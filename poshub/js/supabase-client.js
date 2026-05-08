// ============================================================
// Supabase Client Configuration
// ============================================================
const SUPABASE_URL = 'https://kpcpyjccizroduhynetu.supabase.co';
const SUPABASE_KEY = 'sb_publishable_cJ3HRhn6cbAIOzrqSnauIg_j-sXDk4X';

const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_KEY);

// ============================================================
// Auth Helper
// ============================================================
const Auth = {
  // Get current session
  async getSession() {
    const { data, error } = await db.auth.getSession();
    if (error) return null;
    return data.session;
  },

  // Get current user
  async getUser() {
    const { data, error } = await db.auth.getUser();
    if (error) return null;
    return data.user;
  },

  // Get full profile (user + branch)
  async getProfile() {
    const user = await this.getUser();
    if (!user) return null;

    const { data, error } = await db
      .from('user_profiles')
      .select(`*, branch:branches(*)`)
      .eq('id', user.id)
      .single();

    if (error) return null;
    return data;
  },

  // Sign in
  async signIn(email, password) {
    const { data, error } = await db.auth.signInWithPassword({ email, password });
    if (error) throw error;

    // Update last_login
    await db.from('user_profiles')
      .update({ last_login: new Date().toISOString() })
      .eq('id', data.user.id);

    return data;
  },

  // Sign out
  async signOut() {
    await db.auth.signOut();
    localStorage.removeItem('poshub_branch');
    localStorage.removeItem('poshub_profile');
    window.location.href = 'login.html';
  },

  // Guard: redirect to login if not authenticated
  async requireAuth() {
    const session = await this.getSession();
    if (!session) {
      window.location.href = 'login.html';
      return null;
    }

    // Cache profile for the session
    let profile = JSON.parse(localStorage.getItem('poshub_profile') || 'null');
    if (!profile) {
      profile = await this.getProfile();
      if (profile) {
        localStorage.setItem('poshub_profile', JSON.stringify(profile));
        localStorage.setItem('poshub_branch', JSON.stringify(profile.branch));
      }
    }
    return profile;
  },

  // Get cached branch
  getBranch() {
    return JSON.parse(localStorage.getItem('poshub_branch') || 'null');
  },

  // Get cached profile
  getCachedProfile() {
    return JSON.parse(localStorage.getItem('poshub_profile') || 'null');
  }
};

// Expose globally
window.db = db;
window.Auth = Auth;
