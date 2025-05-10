from pydantic import BaseModel
from typing import List

class SubjectBase(BaseModel):
    name: str

class Subject(SubjectBase):
    id: int
    class Config:
        orm_mode = True

class Test(BaseModel):
    id: int
    subject_id: int
    class Config:
        orm_mode = True

class AnswerSubmission(BaseModel):
    question_id: int
    answer_id: int

class TestSubmission(BaseModel):
    test_id: int
    answers: List[AnswerSubmission]
