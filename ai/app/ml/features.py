"""Feature schema for event success prediction."""

CATEGORICAL_COLUMNS = [
    "student_major",
    "event_type",
    "department",
    "organizer_type",
]
NUMERIC_COLUMNS = [
    "expected_attendance",
    "interest_match_score",
    "skill_match_score",
    "target_major_count",
    "target_interest_count",
]
TARGET = "success"
UNK_TOKEN = "__UNK__"

STUDENT_MAJORS = [
    "Computer Science",
    "Engineering",
    "Business",
    "Arts",
    "Medicine",
    "Education",
    "Law",
    "Architecture",
]

EVENT_TYPES = [
    "workshop",
    "seminar",
    "social",
    "career",
    "sports",
    "volunteer",
    "hackathon",
    "cultural",
]

DEPARTMENTS = [
    "Engineering",
    "Business",
    "Arts",
    "Sciences",
    "Medicine",
    "Student Affairs",
    "Computer Science",
]

ORGANIZER_TYPES = [
    "club_student",
    "club_event",
    "student_affairs",
    "dean_of_faculty",
]
