import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../persistence/store", () => ({
  store: {
    getProfiles: vi.fn().mockResolvedValue([]),
    saveProfile: vi.fn().mockResolvedValue(undefined),
    deleteProfile: vi.fn().mockResolvedValue(undefined),
  },
}));

import { store } from "../persistence/store";
import { useProfileStore } from "./profileStore";

describe("profileStore", () => {
  beforeEach(() => {
    useProfileStore.setState({ activeProfileId: "default", profiles: [] });
    vi.clearAllMocks();
  });

  it("loadProfiles creates and selects a default profile when none exist", async () => {
    vi.mocked(store.getProfiles).mockResolvedValueOnce([]);

    await useProfileStore.getState().loadProfiles();

    expect(store.saveProfile).toHaveBeenCalledOnce();
    expect(useProfileStore.getState().profiles).toHaveLength(1);
    expect(useProfileStore.getState().activeProfileId).toBe("default");
  });

  it("createProfile appends a new profile and persists it", async () => {
    const profile = await useProfileStore.getState().createProfile("Ada", "avatar_1");

    expect(store.saveProfile).toHaveBeenCalledWith(profile);
    expect(useProfileStore.getState().profiles).toContainEqual(profile);
  });

  it("deleteProfile removes the profile and falls back to the next one if it was active", async () => {
    const a = await useProfileStore.getState().createProfile("A", "avatar_1");
    const b = await useProfileStore.getState().createProfile("B", "avatar_1");
    useProfileStore.setState({ activeProfileId: a.id });

    await useProfileStore.getState().deleteProfile(a.id);

    expect(store.deleteProfile).toHaveBeenCalledWith(a.id);
    expect(useProfileStore.getState().profiles.map((p) => p.id)).toEqual([b.id]);
    expect(useProfileStore.getState().activeProfileId).toBe(b.id);
  });
});
