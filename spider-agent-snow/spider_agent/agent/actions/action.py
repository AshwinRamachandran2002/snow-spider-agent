from abc import ABC
from dataclasses import dataclass
from dataclasses import field
from typing import Any
from typing import Optional


@dataclass
class Action(ABC):

    action_type: str = field(
        repr=False,
        metadata={
            "help": 'type of action, e.g. "exec_code", "create_file", "terminate"'
        },
    )

    @classmethod
    def get_action_description(cls) -> str:
        return """
Action: action format
Description: detailed definition of this action type.
Usage: example cases
Observation: the observation space of this action type.
"""

    @classmethod
    def parse_action_from_text(cls, text: str) -> Optional[Any]:
        raise NotImplementedError(
            f"This method should be implemented by subclass: {cls}"
        )
