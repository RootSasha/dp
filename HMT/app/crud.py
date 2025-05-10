from sqlalchemy.orm import Session
from . import models

def get_subjects(db: Session):
    return db.query(models.Subject).all()

def get_tests_by_subject(db: Session, subject_id: int):
    return db.query(models.Test).filter(models.Test.subject_id == subject_id).all()
