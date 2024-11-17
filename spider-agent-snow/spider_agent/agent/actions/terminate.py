import re
from dataclasses import field
from typing import Optional

from .action import Action
from .utils import remove_quote


class Terminate(Action):

    action_type: str = field(
        default="terminate",
        init=False,
        repr=False,
        metadata={
            "help": "terminate action representing the task is finished, or you think it is impossible for you to complete the task"
        },
    )

    output: Optional[str] = field(
        default=None,
        metadata={
            "help": "answer to the task or output file path or 'FAIL', if exists"
        },
    )

    code: str = field(default="")

    @classmethod
    def get_action_description(cls) -> str:
        return """
## Terminate Action
* Signature: Terminate(output="literal_answer_or_output_path")
* Description: This action denotes the completion of the entire task and returns the output file/folder path of the answer. The answer must be saved in a CSV file, and you should tell me the file name.
* Examples:
  - Example1: Terminate(output="result.csv")
"""

    def __repr__(self) -> str:
        return f'{self.__class__.__name__}(output="{self.output}")'

    @classmethod
    def parse_action_from_text(cls, text: str) -> Optional[Action]:
        matches = re.findall(r"Terminate\(output=(.*?)\)", text, flags=re.DOTALL)
        if matches:
            output = matches[-1]
            return cls(output=remove_quote(output))
        return None
