import re
from dataclasses import field
from typing import Optional

from .action import Action
from .utils import remove_quote


class EditFile(Action):
    action_type: str = field(
        default="edit_file",
        init=False,
        repr=False,
        metadata={"help": 'type of action, c.f., "edit_file"'},
    )

    code: str = field(metadata={"help": "code to write into file"})

    filepath: Optional[str] = field(
        default=None, metadata={"help": "name of file to edit"}
    )

    def __repr__(self) -> str:
        return f'EditFile(filepath="{self.filepath}"):\n```\n{self.code.strip()}\n```'

    @classmethod
    def get_action_description(cls) -> str:
        return """
## EditFile
Signature: EditFile(filepath="path/to/file"):
```
file_content
```
Description: This action will overwrite the file specified in the filepath field with the content wrapped in paired ``` symbols. Normally, you need to read the file before deciding to use EditFile to modify it.
Example: EditFile(filepath="hello_world.py"):
```
print("Hello, world!")
```
"""

    @classmethod
    def parse_action_from_text(cls, text: str) -> Optional[Action]:
        matches = re.findall(
            r"EditFile\(filepath=(.*?)\).*?```[ \t]*(\w+)?[ \t]*\r?\n(.*)[\r\n \t]*```",
            text,
            flags=re.DOTALL,
        )
        if matches:
            filepath = matches[-1][0].strip()
            code = matches[-1][2].strip()
            return cls(code=code, filepath=remove_quote(filepath))
        return None
