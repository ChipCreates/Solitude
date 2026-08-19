import { create } from "zustand";
import { store, Profile } from "../persistence/store";

export interface ProfileState {
  activeProfileId: string;
  profiles: Profile[];
  setActiveProfileId: (id: string) => void;
  loadProfiles: () => Promise<void>;
  createProfile: (name: string, avatarId: string) => Promise<Profile>;
  updateProfile: (id: string, updates: Partial<Profile>) => Promise<void>;
  deleteProfile: (id: string) => Promise<void>;
}

export const useProfileStore = create<ProfileState>((set, get) => ({
  activeProfileId: "default",
  profiles: [],
  
  setActiveProfileId: (id: string) => {
    set({ activeProfileId: id });
    import("./uiStore").then(({ useUIStore }) => {
      useUIStore.getState().initializeStore();
    });
  },
  
  loadProfiles: async () => {
    try {
      let loadedProfiles = await store.getProfiles();
      if (loadedProfiles.length === 0) {
        // Create default profile
        const defaultProfile: Profile = {
          id: "default",
          name: "Chip",
          avatarId: "default_avatar",
          createdAt: Date.now(),
          lastPlayed: Date.now()
        };
        await store.saveProfile(defaultProfile);
        loadedProfiles = [defaultProfile];
      }
      
      // Select the most recently played profile if current active is missing or "default" initially
      const active = loadedProfiles.find(p => p.id === get().activeProfileId) || loadedProfiles[0];
      
      set({ profiles: loadedProfiles, activeProfileId: active.id });
    } catch (e) {
      console.error("Failed to load profiles:", e);
      // Fallback state so the game doesn't stall
      set({ 
        profiles: [{ id: "error_fallback", name: "Player 1", avatarId: "default_avatar", createdAt: Date.now(), lastPlayed: Date.now() }],
        activeProfileId: "error_fallback"
      });
    }
  },
  
  createProfile: async (name: string, avatarId: string) => {
    const newProfile: Profile = {
      id: crypto.randomUUID(),
      name,
      avatarId,
      createdAt: Date.now(),
      lastPlayed: Date.now()
    };
    await store.saveProfile(newProfile);
    set(state => ({ profiles: [...state.profiles, newProfile] }));
    return newProfile;
  },

  updateProfile: async (id: string, updates: Partial<Profile>) => {
    const state = get();
    const profile = state.profiles.find(p => p.id === id);
    if (!profile) return;
    const updatedProfile = { ...profile, ...updates };
    await store.saveProfile(updatedProfile);
    set(state => ({
      profiles: state.profiles.map(p => p.id === id ? updatedProfile : p)
    }));
  },
  
  deleteProfile: async (id: string) => {
    await store.deleteProfile(id);
    set(state => {
      const remaining = state.profiles.filter(p => p.id !== id);
      return {
        profiles: remaining,
        activeProfileId: state.activeProfileId === id && remaining.length > 0 ? remaining[0].id : state.activeProfileId
      };
    });
  }
}));
