from openai import OpenAI, AzureOpenAI
from utils.utils import extract_all_blocks
import os

class GPTChat:
    def __init__(self, azure=False, model="gpt-4o", temperature=1) -> None:
        if model in ["gpt-4o", "o1-2024-12-17"] or not azure:
            self.client = OpenAI(
                api_key=os.environ.get("OPENAI_API_KEY"),  # This is the default and can be omitted
            )
        else:
            self.client = AzureOpenAI(
                azure_endpoint = os.environ.get("AZURE_ENDPOIONT"),
                api_key=os.environ.get("AZURE_OPENAI_KEY"),  # This is the default and can be omitted
                api_version="2024-12-01-preview"
            )

        self.messages = []
        self.model = model
        self.temperature = float(temperature)

    def get_model_response(self, prompt, code_format):
        self.messages.append({"role": "user", "content": prompt})
        sql_query = []
        count = 0
        while not sql_query and count < 3:
            count += 1
            try:
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=self.messages,
                    temperature=self.temperature
                )
            except Exception as e:
                print(e)
                return e
            choices = response.choices
            if choices:
                # Extract the main message content
                main_content = choices[0].message.content
                # print("Main Content:\n", main_content)
                
                sql_query = extract_all_blocks(main_content, code_format)
            self.messages.append({"role": "assistant", "content": main_content})
            if not sql_query:
                print(f"sql_query: {sql_query}, count: {count}")
                self.messages.append({"role": "user", "content": f"Please answer in ```{code_format}``` format."})
                continue
                
        return sql_query
    def get_model_response_txt(self, prompt):
        self.messages.append({"role": "user", "content": prompt})
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.messages,
                temperature=self.temperature
            )
        except Exception as e:
            print(e)
            return e
        choices = response.choices
        if choices:
            # Extract the main message content
            main_content = choices[0].message.content
            # print("Main Content:\n", main_content)
            
            # sql_query = extract_all_sql_blocks(main_content)
        self.messages.append({"role": "assistant", "content": main_content})
        # print(f"Current_context_len: {self.get_message_len()}")
        return main_content

    def get_message_len(self):
        return sum([len(i['content']) for i in self.messages])
    
    def init_messages(self):
        self.messages = []

class modelChat():
    def __init__(self, model, tokenizer, device, temperature=1) -> None:
        self.model = model
        self.tokenizer = tokenizer
        self.messages = []
        self.temperature = float(temperature)
        self.device = device

    def get_model_response(self, prompt, code_format):
        self.messages.append({"role": "user", "content": prompt})
        sql_query = []
        count = 0
        while not sql_query and count < 3:
            count += 1
            text = self.tokenizer.apply_chat_template(
                self.messages,
                tokenize=False,
                add_generation_prompt=True
            )
            model_inputs = self.tokenizer([text], return_tensors="pt").to(self.device)
            try:
                generated_ids = self.model.generate(
                    **model_inputs,
                    max_new_tokens=4096
                )
            except Exception as e:
                print(e)
                return e
            generated_ids = [
                output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)
            ]

            response = self.tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]
            sql_query = extract_all_blocks(response, code_format)
            if not sql_query:
                print(f"sql_query: {sql_query}, count: {count}")
                self.messages[-1] = {"role": "user", "content": f"Please answer in ```{code_format}``` format."}
                continue
            self.messages.append({"role": "assistant", "content": response})
            
        return sql_query
    def get_model_response_txt(self, prompt):
        self.messages.append({"role": "user", "content": prompt})
        text = self.tokenizer.apply_chat_template(
            self.messages,
            tokenize=False,
            add_generation_prompt=True
        )
        model_inputs = self.tokenizer([text], return_tensors="pt").to(self.device)
        try:
            generated_ids = self.model.generate(
                **model_inputs,
                max_new_tokens=4096
            )
        except Exception as e:
            print(e)
            return e
        generated_ids = [
            output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)
        ]
        response = self.tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]
        self.messages.append({"role": "assistant", "content": response})
        return response
    def get_message_len(self):
        return sum([len(i['content']) for i in self.messages])

    def init_messages(self):
        self.messages = []