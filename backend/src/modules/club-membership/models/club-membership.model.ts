export interface ClubMembershipModel {
  id: string;
  club_id: string;
  user_id: string;
  role: 'member' | 'lead';
  joined_at: string;
}

