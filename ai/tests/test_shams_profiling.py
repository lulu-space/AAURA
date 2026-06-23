import unittest

from app.services.shams_profiling import analyze_message

LONG_PROFILE = (
    "Hi Shams! I'm a third-year Computer Science student at AAUP. I lead our "
    "programming club and organize weekly hackathon prep sessions. I love building "
    "mobile apps in Flutter and Python, and I'm getting into machine learning and "
    "data analysis for campus projects. Outside class I volunteer with community "
    "outreach programs and help run charity events on campus. I also enjoy public "
    "speaking — I present at student tech talks and debate club meetings. On weekends "
    "I'm into sports, especially basketball and gym workouts, and I do photography for "
    "campus events. I'm curious about entrepreneurship and hope to join a startup "
    "incubator this year."
)


class ShamsProfilingQuickWinsTests(unittest.TestCase):
    def test_vague_message_requests_more_detail(self) -> None:
        result = analyze_message("I'm new here.")
        self.assertTrue(result["needs_detail"])
        self.assertEqual(result["interests"], [])
        self.assertEqual(result["skills"], [])
        self.assertLessEqual(float(result["confidence"]), 0.55)

    def test_help_alone_does_not_trigger_volunteering(self) -> None:
        result = analyze_message(
            "I need help with homework and midterms in my study group sessions."
        )
        self.assertFalse(result["needs_detail"])
        self.assertNotIn("Volunteering", result["interests"])
        self.assertIn("Study Groups", result["interests"])

    def test_rich_message_extracts_interests_and_skills(self) -> None:
        result = analyze_message(
            "I lead our programming club, love Python hackathons, volunteer in the "
            "community, and enjoy public speaking at campus events."
        )
        self.assertFalse(result["needs_detail"])
        self.assertIn("Programming", result["interests"])
        self.assertIn("Volunteering", result["interests"])
        self.assertIn("Public Speaking", result["interests"])
        self.assertIn("Python", result["skills"])
        self.assertGreaterEqual(float(result["confidence"]), 0.7)

    def test_traits_are_capped(self) -> None:
        result = analyze_message(
            "I lead teams, write code, volunteer, debate on stage, study research, "
            "play sports, design art, and run a startup business."
        )
        self.assertLessEqual(len(result["traits"]), 4)

    def test_long_profile_extracts_year_major_and_goals(self) -> None:
        result = analyze_message(LONG_PROFILE)
        self.assertFalse(result["needs_detail"])
        self.assertEqual(result["major"], "Computer Science")
        self.assertEqual(result["year"], "3rd Year")
        self.assertEqual(result["academic_year"], 3)
        goals = result["goals"]
        self.assertTrue(any("startup incubator" in goal.lower() for goal in goals))


if __name__ == "__main__":
    unittest.main()
