from dataclasses import dataclass
from dataclasses import field
from typing import Optional

from .action import Action


@dataclass
class CreateFile(Action):

    action_type: str = field(
        default="create_file",
        init=False,
        repr=False,
        metadata={"help": 'type of action, c.f., "create_file"'},
    )

    code: str = field(metadata={"help": "code to write into file"})

    filepath: Optional[str] = field(
        default=None, metadata={"help": "name of file to create"}
    )

    def __repr__(self) -> str:
        return f'CreateFile(filepath="{self.filepath}"):\n```\n{self.code.strip()}\n```'

    @classmethod
    def get_action_description(cls) -> str:
        return """
## CreateFile
Signature: CreateFile(filepath="path/to/file"):
```
file_content
```
Description: This action will create a file in the field `filepath` with the content wrapped by paired ``` symbols. Make sure the file content is complete and correct. If the file already exists, you can only use EditFile to modify it.
Example: CreateFile(filepath="hello_world.py"):
```
print("Hello, world!")
```
"""
