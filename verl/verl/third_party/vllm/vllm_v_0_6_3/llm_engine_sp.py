# Copyright 2024 Bytedance Ltd. and/or its affiliates
# Copyright 2023 The vLLM team.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Adapted from https://github.com/vllm-project/vllm/blob/main/vllm/engine/llm_engine.py
import os
from functools import partial
from typing import Callable, Dict, Optional, Type, Union, List
import time
import torch
import torch.nn as nn
from vllm.config import (
    CacheConfig,
    DecodingConfig,
    DeviceConfig,
    EngineConfig,
    LoadConfig,
    LoRAConfig,
    ModelConfig,
    ObservabilityConfig,
    ParallelConfig,
    PromptAdapterConfig,
    SchedulerConfig,
    SpeculativeConfig,
)
from omegaconf import DictConfig
from vllm.core.scheduler import Scheduler
from vllm.engine.arg_utils import EngineArgs
from vllm.engine.llm_engine import LLMEngine, SchedulerContext, SchedulerOutputState, _load_generation_config_dict
from vllm.engine.metrics_types import StatLoggerBase
from vllm.engine.output_processor.interfaces import SequenceGroupOutputProcessor
from vllm.engine.output_processor.stop_checker import StopChecker
from vllm.executor.executor_base import ExecutorBase
from vllm.inputs import INPUT_REGISTRY, InputRegistry
from vllm.inputs.preprocess import InputPreprocessor
from vllm.logger import init_logger
from vllm.sequence import Sequence, ExecuteModelRequest
from vllm.tracing import init_tracer
from vllm.transformers_utils.detokenizer import Detokenizer
from vllm.transformers_utils.tokenizer import AnyTokenizer
from vllm.usage.usage_lib import UsageContext, is_usage_stats_enabled, usage_message
from vllm.utils import Counter, weak_bind
from vllm.outputs import (EmbeddingRequestOutput, RequestOutput)

from .arg_utils import EngineArgs
from .config import LoadConfig, ModelConfig
from .tokenizer import TokenizerGroup
from verl.workers.reward_model.reward_utils import execute_sql_with_timeout, get_api_name
import uuid
import datetime

logger = init_logger(__name__)
_LOCAL_LOGGING_INTERVAL_SEC = 5


class SQLExecutor():

    def __init__(self, tokenizer_group, sql_executor_config):
        self.parent_seq_ids_completions = {}
        self.monitor_parent_seq_ids = {}
        self.initial_prompts = {}
        self.calls_per_parent_seq_id = {}

        self.monitor_token_id = [522, 11748, 18063, 397]
        self.start_token_id_1 = [366, 11748, 18063, 397]
        self.start_token_id_2 = [27, 11748, 18063, 397]
        self.tokenizer = tokenizer_group.tokenizer

        self.exec_func_sql = execute_sql_with_timeout
        self.beginning = True
        self.sqlite_source_path = sql_executor_config.sqlite_source_path
        self.max_calls = sql_executor_config.max_calls

        self.logging = False
        self.log_path = f"logs/sql_executor_{str(uuid.uuid4())}_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log"

    def fetch_execution_result(self, completion, seq_group_id):
        for index in range(len(completion)-4, 0, -1):
            if completion[index:index+4] == self.start_token_id_1 or completion[index:index+4] == self.start_token_id_2:
                sql_string = self.tokenizer.decode(completion[index+4:-4])
                kwargs = self.initial_prompts[str(seq_group_id)]
                start = time.time()
                exec_result = self.exec_func_sql(sql_string, max_len=200, **kwargs)
                exec_result = "<exec_result>\n" + exec_result + "\n</exec_result>\n"
                if self.logging:
                    with open(self.log_path, "a") as f:
                        f.write(f"executed below SQL with kwargs {kwargs}\n")
                        f.write(f"{sql_string}\n")
                        f.write(f"result is {exec_result}\n")
                        f.write(f"time for api is {time.time()-start}")
                print(f"executed below SQL with kwargs {kwargs}\n, {sql_string}\n, result is {exec_result}\n")
                return self.tokenizer.encode(exec_result)
        return []

    def remove(self, request_id):
        if request_id in self.parent_seq_ids_completions:
            del self.parent_seq_ids_completions[request_id]

        if request_id in self.monitor_parent_seq_ids:
            del self.monitor_parent_seq_ids[request_id]

    def process(self, outputs, scheduler_outputs):
        """
        Each new completion request has a unique request_id in Scheduler Outputs.
        Depending on number of rollouts, in each Scheduler Ouput request id, multiple parent seq id are started
        """

        if self.beginning:
            self.beginning = False
            return outputs

        # Save the initial prompts for each request ID
        for scheduled_seq_group in scheduler_outputs.scheduled_seq_groups:
            seq_group = scheduled_seq_group.seq_group
            seq_group_id = seq_group.request_id
            sqlite_path = seq_group.sampling_params.sqlite_path
            example_id = seq_group.sampling_params.example_id
            if seq_group_id not in self.initial_prompts:
                if self.logging:
                    with open(self.log_path, "a") as f:
                        f.write(f"Saving initial prompt for {example_id} which has seq_group_id {seq_group_id} and sqlite_path {sqlite_path}\n")
                self.initial_prompts[str(seq_group_id)] = {
                    "api": get_api_name(example_id),
                    "sqlite_path": os.path.join(self.sqlite_source_path, sqlite_path) if sqlite_path else '',
                }

        # Assumption: There is only one Sampler Output Object
        assert len(outputs) == 1
        outputs = outputs[0]
        # Process each CompletionSequenceGroupOutput object
        for index, completion_seq_output in enumerate(outputs.outputs):
            seq_group_id = scheduler_outputs.scheduled_seq_groups[index].seq_group.request_id
            if self.logging:
                with open(self.log_path, "a") as f:
                    f.write(f"processing group {seq_group_id}\n")
            seq_id_analyzed = []
            for seq_output in completion_seq_output.samples:
                seq_id = seq_output.parent_seq_id

                if seq_id in seq_id_analyzed:
                    print("WARNING", outputs)

                seq_id_analyzed.append(seq_id)

                if self.logging:
                    with open(self.log_path, "a") as f:
                        f.write(f"processing seq_id {seq_id}\n")

                # Check if the sequence ID is being monitored
                if seq_id in self.monitor_parent_seq_ids:
                    if self.logging:
                        with open(self.log_path, "a") as f:
                            f.write(f"Monitoring seq_id {seq_id}\n")

                    monitor_info = self.monitor_parent_seq_ids[seq_id]

                    actual_output_token = seq_output.output_token
                    replacement_token = monitor_info["exec_result"][monitor_info["curr_pointer"]]
                    monitor_info["curr_pointer"] += 1

                    # replace output token
                    seq_output.output_token = replacement_token
                    
                    # replace the logprobs also
                    seq_output.logprobs[replacement_token] = seq_output.logprobs[actual_output_token]
                    if replacement_token != actual_output_token:
                        del seq_output.logprobs[actual_output_token]

                    # Remove from monitoring if all tokens have been processed
                    if monitor_info["curr_pointer"] >= len(monitor_info["exec_result"]):
                        if self.logging:
                            with open(self.log_path, "a") as f:
                                f.write(f"Removing seq_id {seq_id} from monitoring\n")
                        del self.monitor_parent_seq_ids[seq_id]

                output_token = seq_output.output_token
                if self.logging:
                    with open(self.log_path, "a") as f:
                        f.write(f"Output token {output_token}\n")
                        f.write(f"Output word {self.tokenizer.decode([output_token])}\n")

                # Store the output token for the sequence ID
                if seq_id not in self.parent_seq_ids_completions:
                    self.parent_seq_ids_completions[seq_id] = []
                self.parent_seq_ids_completions[seq_id].append(output_token)

                # Check for the monitor token sequence in completions
                completions = self.parent_seq_ids_completions[seq_id]
                if completions[-4:] == self.monitor_token_id:
                    if self.logging:
                        with open(self.log_path, "a") as f:
                            f.write(f"Detected monitor token for seq_id {seq_id}\n")

                    # Check if a lot of calls have been made for this seq_id
                    if seq_id not in self.calls_per_parent_seq_id:
                        self.calls_per_parent_seq_id[seq_id] = [time.time()]
                    self.calls_per_parent_seq_id[seq_id] += [time.time()]
                    used_time = self.calls_per_parent_seq_id[seq_id][-1] - self.calls_per_parent_seq_id[seq_id][0]
                    if used_time > self.max_calls:
                        if self.logging:
                            with open(self.log_path, "a") as f:
                                f.write(f"Exceeded max calls for seq_id {seq_id}\n")
                        print(f"Timeout max calls for seq_id {seq_id}, time: {used_time}\n")

                        self.monitor_parent_seq_ids[seq_id] = {
                            "exec_result": [self.tokenizer.eos_token_id],
                            "curr_pointer": 0
                        }
                    else:
                        if self.logging:
                            with open(self.log_path, "a") as f:
                                f.write(f"Making API call for seq_id {seq_id}\n")
                        self.monitor_parent_seq_ids[seq_id] = {
                            "exec_result": self.fetch_execution_result(completions, seq_group_id),
                            "curr_pointer": 0
                        }

        return [outputs]

class LLMEngine(LLMEngine):
    """An LLM engine that receives requests and generates texts.

    This is the main class for the vLLM engine. It receives requests
    from clients and generates texts from the LLM. It includes a tokenizer, a
    language model (possibly distributed across multiple GPUs), and GPU memory
    space allocated for intermediate states (aka KV cache). This class utilizes
    iteration-level scheduling and efficient memory management to maximize the
    serving throughput.

    The :class:`~vllm.LLM` class wraps this class for offline batched inference
    and the :class:`AsyncLLMEngine` class wraps this class for online serving.

    The config arguments are derived from :class:`~vllm.EngineArgs`. (See
    :ref:`engine_args`)

    Args:
        model_config: The configuration related to the LLM model.
        cache_config: The configuration related to the KV cache memory
            management.
        parallel_config: The configuration related to distributed execution.
        scheduler_config: The configuration related to the request scheduler.
        device_config: The configuration related to the device.
        lora_config (Optional): The configuration related to serving multi-LoRA.
        speculative_config (Optional): The configuration related to speculative
            decoding.
        executor_class: The model executor class for managing distributed
            execution.
        prompt_adapter_config (Optional): The configuration related to serving
            prompt adapters.
        log_stats: Whether to log statistics.
        usage_context: Specified entry point, used for usage info collection.
    """

    def __init__(
        self,
        # NOTE(sgm): first two arguments are added for verl
        model: Union[nn.Module, Dict],  # model itself or its parameter dict
        tokenizer: nn.Module,
        sql_executor_config: DictConfig,
        # NOTE(sgm): vllm original arguments
        model_config: ModelConfig,
        cache_config: CacheConfig,
        parallel_config: ParallelConfig,
        scheduler_config: SchedulerConfig,
        device_config: DeviceConfig,
        load_config: LoadConfig,
        lora_config: Optional[LoRAConfig],
        speculative_config: Optional[SpeculativeConfig],
        decoding_config: Optional[DecodingConfig],
        observability_config: Optional[ObservabilityConfig],
        prompt_adapter_config: Optional[PromptAdapterConfig],
        executor_class: Type[ExecutorBase],
        log_stats: bool,
        usage_context: UsageContext = UsageContext.ENGINE_CONTEXT,
        stat_loggers: Optional[Dict[str, StatLoggerBase]] = None,
        input_registry: InputRegistry = INPUT_REGISTRY,
        use_cached_outputs: bool = False,
    ) -> None:
        logger.info(
            "Initializing an LLM engine (v%s) with config: "
            "model=%r, speculative_config=%r, tokenizer=%r, "
            "skip_tokenizer_init=%s, tokenizer_mode=%s, revision=%s, "
            "override_neuron_config=%s, "
            "rope_scaling=%r, rope_theta=%r, tokenizer_revision=%s, "
            "trust_remote_code=%s, dtype=%s, max_seq_len=%d, "
            "download_dir=%r, load_format=%s, tensor_parallel_size=%d, "
            "pipeline_parallel_size=%d, "
            "disable_custom_all_reduce=%s, quantization=%s, "
            "enforce_eager=%s, kv_cache_dtype=%s, "
            "quantization_param_path=%s, device_config=%s, "
            "decoding_config=%r, observability_config=%r, "
            "seed=%d, served_model_name=%s, use_v2_block_manager=%s, "
            "num_scheduler_steps=%d, chunked_prefill_enabled=%s "
            "multi_step_stream_outputs=%s, enable_prefix_caching=%s, "
            "use_async_output_proc=%s, use_cached_outputs=%s, "
            "mm_processor_kwargs=%s)",
            0.02,
            model_config.model,
            speculative_config,
            model_config.tokenizer,
            model_config.skip_tokenizer_init,
            model_config.tokenizer_mode,
            model_config.revision,
            model_config.override_neuron_config,
            model_config.rope_scaling,
            model_config.rope_theta,
            model_config.tokenizer_revision,
            model_config.trust_remote_code,
            model_config.dtype,
            model_config.max_model_len,
            load_config.download_dir,
            load_config.load_format,
            parallel_config.tensor_parallel_size,
            parallel_config.pipeline_parallel_size,
            parallel_config.disable_custom_all_reduce,
            model_config.quantization,
            model_config.enforce_eager,
            cache_config.cache_dtype,
            model_config.quantization_param_path,
            device_config.device,
            decoding_config,
            observability_config,
            model_config.seed,
            model_config.served_model_name,
            scheduler_config.use_v2_block_manager,
            scheduler_config.num_scheduler_steps,
            scheduler_config.chunked_prefill_enabled,
            scheduler_config.multi_step_stream_outputs,
            cache_config.enable_prefix_caching,
            model_config.use_async_output_proc,
            use_cached_outputs,
            model_config.mm_processor_kwargs,
        )
        # TODO(woosuk): Print more configs in debug mode.
        self.model_config = model_config
        self.cache_config = cache_config
        self.lora_config = lora_config
        self.parallel_config = parallel_config
        self.scheduler_config = scheduler_config
        self.device_config = device_config
        self.speculative_config = speculative_config
        self.load_config = load_config
        self.decoding_config = decoding_config or DecodingConfig()
        self.prompt_adapter_config = prompt_adapter_config
        self.observability_config = observability_config or ObservabilityConfig()
        self.log_stats = log_stats
        self.use_cached_outputs = use_cached_outputs

        if not self.model_config.skip_tokenizer_init:
            self.tokenizer = self._init_tokenizer(tokenizer)
            self.detokenizer = Detokenizer(self.tokenizer)
            tokenizer_group = self.get_tokenizer_group()
        else:
            self.tokenizer = None
            self.detokenizer = None
            tokenizer_group = None

        # Ensure that the function doesn't contain a reference to self,
        # to avoid engine GC issues
        def get_tokenizer_for_seq(sequence: Sequence) -> AnyTokenizer:
            assert tokenizer_group, "tokenizer_group cannot be None, " "make sure skip_tokenizer_init is False"
            return tokenizer_group.get_lora_tokenizer(sequence.lora_request)

        self.seq_counter = Counter()
        self.generation_config_fields = _load_generation_config_dict(model_config)

        self.input_preprocessor = InputPreprocessor(model_config, self.tokenizer)

        self.input_registry = input_registry
        self.input_processor = input_registry.create_input_processor(model_config)

        self.model_executor = executor_class(
            model=model,  # add for spmd_gpu_executor
            model_config=model_config,
            cache_config=cache_config,
            parallel_config=parallel_config,
            scheduler_config=scheduler_config,
            device_config=device_config,
            lora_config=lora_config,
            speculative_config=speculative_config,
            load_config=load_config,
            prompt_adapter_config=prompt_adapter_config,
            observability_config=self.observability_config,
        )

        if not self.model_config.embedding_mode:
            self._initialize_kv_caches()

        # If usage stat is enabled, collect relevant info.
        if is_usage_stats_enabled():
            from vllm.model_executor.model_loader import get_architecture_class_name

            usage_message.report_usage(
                get_architecture_class_name(model_config),
                usage_context,
                extra_kvs={
                    # Common configuration
                    "dtype": str(model_config.dtype),
                    "tensor_parallel_size": parallel_config.tensor_parallel_size,
                    "block_size": cache_config.block_size,
                    "gpu_memory_utilization": cache_config.gpu_memory_utilization,
                    # Quantization
                    "quantization": model_config.quantization,
                    "kv_cache_dtype": str(cache_config.cache_dtype),
                    # Feature flags
                    "enable_lora": bool(lora_config),
                    "enable_prompt_adapter": bool(prompt_adapter_config),
                    "enable_prefix_caching": cache_config.enable_prefix_caching,
                    "enforce_eager": model_config.enforce_eager,
                    "disable_custom_all_reduce": parallel_config.disable_custom_all_reduce,
                },
            )

        if self.tokenizer:
            # Ping the tokenizer to ensure liveness if it runs in a
            # different process.
            self.tokenizer.ping()

        self.cached_scheduler_outputs = [
            SchedulerOutputState() for _ in range(self.parallel_config.pipeline_parallel_size)
        ]

        self.scheduler_contexts = [
            SchedulerContext(multi_step_stream_outputs=self.scheduler_config.multi_step_stream_outputs)
            for _ in range(self.parallel_config.pipeline_parallel_size)
        ]

        if model_config.use_async_output_proc:
            process_model_outputs = weak_bind(self._process_model_outputs)

            self.async_callbacks = [
                partial(process_model_outputs, ctx=self.scheduler_contexts[v_id])
                for v_id in range(self.parallel_config.pipeline_parallel_size)
            ]
        else:
            self.async_callbacks = []

        # Currently used by AsyncLLMEngine to ensure quick append
        # of request outputs to asyncio queues
        self.process_request_outputs_callback: Optional[Callable] = None

        # Create the scheduler.
        # NOTE: the cache_config here have been updated with the numbers of
        # GPU and CPU blocks, which are profiled in the distributed executor.
        self.scheduler = [
            Scheduler(
                scheduler_config,
                cache_config,
                lora_config,
                parallel_config.pipeline_parallel_size,
                self.async_callbacks[v_id] if model_config.use_async_output_proc else None,
            ) for v_id in range(parallel_config.pipeline_parallel_size)
        ]

        # Metric Logging.
        if self.log_stats:
            if stat_loggers is not None:
                self.stat_loggers = stat_loggers
            else:
                # Lazy import for prometheus multiprocessing.
                # We need to set PROMETHEUS_MULTIPROC_DIR environment variable
                # before prometheus_client is imported.
                # See https://prometheus.github.io/client_python/multiprocess/
                from vllm.engine.metrics import LoggingStatLogger, PrometheusStatLogger

                self.stat_loggers = {
                    "logging":
                        LoggingStatLogger(local_interval=_LOCAL_LOGGING_INTERVAL_SEC),
                    "prometheus":
                        PrometheusStatLogger(
                            local_interval=_LOCAL_LOGGING_INTERVAL_SEC,
                            labels=dict(model_name=model_config.served_model_name),
                            max_model_len=self.model_config.max_model_len,
                        ),
                }
                self.stat_loggers["prometheus"].info("cache_config", self.cache_config)

        self.tracer = None
        if self.observability_config.otlp_traces_endpoint:
            self.tracer = init_tracer("vllm.llm_engine", self.observability_config.otlp_traces_endpoint)

        # Create sequence output processor, e.g. for beam search or
        # speculative decoding.
        self.output_processor = SequenceGroupOutputProcessor.create_output_processor(
            self.scheduler_config,
            self.detokenizer,
            self.scheduler,
            self.seq_counter,
            get_tokenizer_for_seq,
            stop_checker=StopChecker(
                self.scheduler_config.max_model_len,
                get_tokenizer_for_seq,
            ),
        )

        self.sql_executor_context = SQLExecutor(self.tokenizer, sql_executor_config)

    # TODO(sgm): add for verl but we may not tokenizer in Rollout
    def _init_tokenizer(self, tokenizer, **tokenizer_init_kwargs):
        init_kwargs = dict(enable_lora=bool(self.lora_config),
                           max_num_seqs=self.scheduler_config.max_num_seqs,
                           max_input_length=None)
        init_kwargs.update(tokenizer_init_kwargs)
        return TokenizerGroup(tokenizer, **init_kwargs)

    def init_cache_engine(self):
        # TODO: check whether we should rebuild the CUDAGraph every iter when offload/load KVCache
        # Re-capture CUDAGraph would be time-consuming
        self.model_executor.init_cache_engine()

    def free_cache_engine(self):
        self.model_executor.free_cache_engine()

    # NOTE(sgm): currently, we only support GPU executor
    # The GPUExecutor remove the Ray dependency
    @classmethod
    def _get_executor_cls(cls, engine_config: EngineConfig) -> Type[ExecutorBase]:
        distributed_executor_backend = engine_config.parallel_config.distributed_executor_backend
        # Initialize the cluster and specify the executor class.]
        assert (engine_config.device_config.device_type == "cuda"
               ), "Currently, the vllm in verl only support running on GPU"

        # print('Waiting for debugger'); import os,debugpy; debugpy.listen(('localhost', 5678 + int(os.getenv('RANK', '0')))); debugpy.wait_for_client()
        if engine_config.parallel_config.world_size == 1:
            engine_config.load_config.load_format = "dummy_hf"

        from .spmd_gpu_executor import SPMDGPUExecutor

        executor_class = SPMDGPUExecutor

        return executor_class

    @classmethod
    def from_engine_args(
        cls,
        model,
        tokenizer,
        sql_executor_config: DictConfig,
        engine_args: EngineArgs,
        usage_context: UsageContext = UsageContext.ENGINE_CONTEXT,
        stat_loggers: Optional[Dict[str, StatLoggerBase]] = None,
    ) -> "LLMEngine":
        """Creates an LLM engine from the engine arguments."""
        # Create the engine configs.
        engine_config = engine_args.create_engine_config()
        executor_class = cls._get_executor_cls(engine_config)
        # Initialize the cluster and specify the executor class.
        assert (engine_config.device_config.device_type == "cuda"
               ), "Currently, the vllm in verl only support running on GPU"

        from .spmd_gpu_executor import SPMDGPUExecutor

        executor_class = SPMDGPUExecutor

        # Create the LLM engine.
        engine = cls(
            model,
            tokenizer,
            sql_executor_config,
            **engine_config.to_dict(),
            executor_class=executor_class,
            log_stats=not engine_args.disable_log_stats,
            usage_context=usage_context,
            stat_loggers=stat_loggers,
        )
        return engine

    def sync_model_weights(self, actor_weights: Dict[str, torch.Tensor], load_format: str) -> None:
        self.model_executor.sync_model_weights(actor_weights=actor_weights, load_format=load_format)

    def offload_model_weights(self) -> None:
        self.model_executor.offload_model_weights()

    def step(self) -> List[Union[RequestOutput, EmbeddingRequestOutput]]:
        if self.parallel_config.pipeline_parallel_size > 1:
            raise NotImplementedError(
                "Pipeline parallelism is only supported through AsyncLLMEngine "
                "as performance will be severely degraded otherwise.")

        # For llm_engine, there is no pipeline parallel support, so the engine
        # used is always 0.
        virtual_engine = 0

        # These are cached outputs from previous iterations. None if on first
        # iteration
        cached_outputs = self.cached_scheduler_outputs[virtual_engine]
        seq_group_metadata_list = cached_outputs.seq_group_metadata_list
        scheduler_outputs = cached_outputs.scheduler_outputs
        allow_async_output_proc = cached_outputs.allow_async_output_proc

        ctx = self.scheduler_contexts[virtual_engine]

        # Clear outputs for each new scheduler iteration
        ctx.request_outputs.clear()

        # Skip the scheduler if there are any remaining steps in the seq groups.
        # This ensures that the scheduler is only called again when the current
        # batch has completed.
        if not self._has_remaining_steps(seq_group_metadata_list):
            # Schedule iteration
            (seq_group_metadata_list, scheduler_outputs,
             allow_async_output_proc
             ) = self.scheduler[virtual_engine].schedule()

            ctx.seq_group_metadata_list = seq_group_metadata_list
            ctx.scheduler_outputs = scheduler_outputs

            # Maybe switch from async mode to sync mode
            if not allow_async_output_proc and len(ctx.output_queue) > 0:
                self._process_model_outputs(ctx=ctx)

            if (self.scheduler_config.is_multi_step
                    and scheduler_outputs.num_lookahead_slots > 0):
                # cache the scheduler outputs for the next iteration if we have
                # lookahead slots
                self._cache_scheduler_outputs_for_multi_step(
                    virtual_engine, seq_group_metadata_list, scheduler_outputs,
                    allow_async_output_proc)

        assert seq_group_metadata_list is not None
        assert scheduler_outputs is not None

        if not scheduler_outputs.is_empty():
            
            finished_requests_ids = self.scheduler[
                virtual_engine].get_and_reset_finished_requests_ids()

            # Check if we have a cached last_output from the previous iteration.
            # For supporting PP this is probably the best way to pass the
            # sampled_token_ids, as a separate broadcast over all the PP stages
            # will cause one virtual engine's microbatch to block the pipeline.
            last_sampled_token_ids = \
                self._get_last_sampled_token_ids(virtual_engine)

            execute_model_req = ExecuteModelRequest(
                seq_group_metadata_list=seq_group_metadata_list,
                blocks_to_swap_in=scheduler_outputs.blocks_to_swap_in,
                blocks_to_swap_out=scheduler_outputs.blocks_to_swap_out,
                blocks_to_copy=scheduler_outputs.blocks_to_copy,
                num_lookahead_slots=scheduler_outputs.num_lookahead_slots,
                running_queue_size=scheduler_outputs.running_queue_size,
                finished_requests_ids=finished_requests_ids,
                # We use ExecuteModelRequest to pass the last sampled_token_ids
                # to each of the non-last PP stages for in-place prepare_input.
                last_sampled_token_ids=last_sampled_token_ids)

            if allow_async_output_proc:
                execute_model_req.async_callback = self.async_callbacks[
                    virtual_engine]

            outputs = self.model_executor.execute_model(
                execute_model_req=execute_model_req)

            # We need to do this here so that last step's sampled_token_ids can
            # be passed to the next iteration for PP.
            if self.scheduler_config.is_multi_step:
                self._update_cached_scheduler_output(virtual_engine, outputs)
        else:
            
            # Nothing scheduled => If there is pending async postprocessor,
            # then finish it here.
            if len(ctx.output_queue) > 0:
                self._process_model_outputs(ctx=ctx)
            # No outputs in this case
            outputs = []

        # Finish the current step for all the sequence groups.
        if self.scheduler_config.is_multi_step:
            for seq_group in seq_group_metadata_list:
                seq_group.finish_step()

        if not self._has_remaining_steps(seq_group_metadata_list):
            
            # clear the cache if we have finished all the steps.
            if self.scheduler_config.is_multi_step:
                self.cached_scheduler_outputs[0] = SchedulerOutputState()

            # is_first_step_output is True only when the num_steps of all
            # the sequences are 1. When the num_steps > 1,
            # multi_step_model_runner does the first-step output append.
            is_first_step_output: bool = False if not seq_group_metadata_list \
                else seq_group_metadata_list[0].state.num_steps == 1

            # Add results to the output_queue
            if self.sql_executor_context.logging:
                with open(self.sql_executor_context.log_path, "a") as f:
                    f.write(f"llm engine otuput before process {outputs}\n")
                    f.write(f"scheduler outputs {scheduler_outputs}\n")
            outputs = self.sql_executor_context.process(outputs, scheduler_outputs)
            if self.sql_executor_context.logging:
                with open(self.sql_executor_context.log_path, "a") as f:
                    f.write(f"llm engine otuput after process {outputs}\n")
            ctx.append_output(outputs=outputs,
                              seq_group_metadata_list=seq_group_metadata_list,
                              scheduler_outputs=scheduler_outputs,
                              is_async=allow_async_output_proc,
                              is_last_step=True,
                              is_first_step_output=is_first_step_output)

            if outputs and allow_async_output_proc:
                assert len(outputs) == 1, (
                    "Async postprocessor expects only a single output set")

                self._advance_to_next_step(
                    outputs[0], seq_group_metadata_list,
                    scheduler_outputs.scheduled_seq_groups)

            # Check if need to run the usual non-async path
            if not allow_async_output_proc:
                
                self._process_model_outputs(ctx=ctx)

                # Log stats.
                self.do_log_stats(scheduler_outputs, outputs)

                # Tracing
                self.do_tracing(scheduler_outputs)
        else:
            # Multi-step case
            return ctx.request_outputs

        if not self.has_unfinished_requests():
            # Drain async postprocessor (if exists)
            if len(ctx.output_queue) > 0:
                self._process_model_outputs(ctx=ctx)
            assert len(ctx.output_queue) == 0

            # Stop the execute model loop in parallel workers until there are
            # more requests to process. This avoids waiting indefinitely in
            # torch.distributed ops which may otherwise timeout, and unblocks
            # the RPC thread in the workers so that they can process any other
            # queued control plane messages, such as add/remove lora adapters.
            logger.debug("Stopping remote worker execution loop.")
            self.model_executor.stop_remote_worker_execution_loop()


        return ctx.request_outputs
