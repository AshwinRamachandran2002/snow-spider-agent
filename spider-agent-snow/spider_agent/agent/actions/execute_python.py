import re
from dataclasses import dataclass
from dataclasses import field
from typing import Optional

from .action import Action
from .utils import remove_quote


@dataclass
class ExecutePython(Action):

    action_type: str = field(
        default="exec_code",
        init=False,
        repr=False,
        metadata={"help": 'type of action, c.f., "exec_code"'},
    )

    code: str = field(metadata={"help": "python code to execute"})

    @classmethod
    def get_action_description(cls) -> str:
        return '''
## ExecutePython Action
* Signature: (code="Python code")
* Description: This action string will execute Python code in the `code` field on an iPython environment. The iPython will maintain the kernel state between actions, so you can define variables and functions in one action and use them in the next action. Multi-line code is supported.
* Example: ExecutePython(code="""a = 1
print(a)""")
'''

    @classmethod
    def parse_action_from_text(cls, text: str) -> Optional[Action]:
        matches = re.findall(r"ExecutePython\(code=(.*?)\)$", text, flags=re.DOTALL)
        if matches:
            code = matches[-1]
            return cls(code=remove_quote(code))
        return None

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(code={self.code})"
