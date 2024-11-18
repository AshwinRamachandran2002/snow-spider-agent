import re
from dataclasses import dataclass
from dataclasses import field
from typing import Optional

from .action import Action
from .utils import remove_quote


@dataclass
class Bash(Action):

    action_type: str = field(
        default="exec_code",
        init=False,
        repr=False,
        metadata={"help": 'type of action, c.f., "exec_code"'},
    )

    code: str = field(metadata={"help": "command to execute"})

    @classmethod
    def get_action_description(cls) -> str:
        return """
## Bash Action
* Signature: Bash(code="shell_command")
* Description: This action string will execute a valid shell command in the `code` field. Only non-interactive commands are supported. Commands like "vim" and viewing images directly (e.g., using "display") are not allowed.
* Example: Bash(code="ls -l")
"""

    @classmethod
    def parse_action_from_text(cls, text: str) -> Optional[Action]:
        matches = re.findall(r"Bash\(code=(.*?)\)", text, flags=re.DOTALL)
        if matches:
            code = matches[-1]
            return cls(code=remove_quote(code))
        return None

    def __repr__(self) -> str:
        return f'{self.__class__.__name__}(code="{self.code}")'
