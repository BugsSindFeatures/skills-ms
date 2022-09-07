from pydantic import BaseModel, Field

from api.utils.docs import example


class Skill(BaseModel):
    id: str = Field(description="ID of the skill")
    name: str = Field(description="Name of the skill")
    courses: list[str] = Field(description="List of course ids")
    instructors: list[None] = Field(description="List of instructors")
    exam_dates: list[None] = Field(description="List of exam dates")
    dependencies: list[str] = Field(description="List of course dependencies")

    Config = example(
        id="software_developer",
        name="Software Developer",
        courses=["python"],
        instructors=[],
        dependencies=["web_developer"],
    )
