from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from . import crud, schemas, database

router = APIRouter()

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/subjects", response_model=List[schemas.Subject])
def list_subjects(db: Session = Depends(get_db)):
    return crud.get_subjects(db)

@router.get("/tests/{subject_id}", response_model=List[schemas.Test])
def list_tests(subject_id: int, db: Session = Depends(get_db)):
    return crud.get_tests_by_subject(db, subject_id)

@router.post("/submit")
def submit_test(submission: schemas.TestSubmission):
    return {"received": submission.dict()}
