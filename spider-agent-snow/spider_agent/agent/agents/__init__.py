from .prompt_agent import PromptAgent
from .snowpark_agent import SnowparkAgent

AGENT_NAME_CLASS_MAP = {
    "default-agent": PromptAgent,
    "snowpark-agent": SnowparkAgent,
}
