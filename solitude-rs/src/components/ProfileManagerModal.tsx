import React, { useState } from "react";
import { useProfileStore } from "../store/profileStore";
import { User, Trash2, Plus, X } from "lucide-react";

interface ProfileManagerModalProps {
  onClose: () => void;
}

export const ProfileManagerModal: React.FC<ProfileManagerModalProps> = ({ onClose }) => {
  const { profiles, activeProfileId, setActiveProfileId, createProfile, updateProfile, deleteProfile } = useProfileStore();
  
  const [isCreating, setIsCreating] = useState(false);
  const [newName, setNewName] = useState("");
  const [editProfileId, setEditProfileId] = useState<string | null>(null);
  const [editName, setEditName] = useState("");
  const [errorMsg, setErrorMsg] = useState("");

  const handleCreate = async () => {
    if (!newName.trim()) {
      setErrorMsg("Name cannot be empty");
      return;
    }
    await createProfile(newName.trim(), "default_avatar");
    setNewName("");
    setIsCreating(false);
    setErrorMsg("");
  };

  const handleStartEdit = (id: string, currentName: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setEditProfileId(id);
    setEditName(currentName);
  };

  const handleSaveEdit = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (editProfileId && editName.trim()) {
      await updateProfile(editProfileId, { name: editName.trim() });
    }
    setEditProfileId(null);
  };

  const handleCancelEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    setEditProfileId(null);
  };

  const handleDelete = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (profiles.length <= 1) {
      alert("You cannot delete the last remaining profile.");
      return;
    }
    if (confirm("Are you sure you want to delete this profile? All statistics and progress will be lost!")) {
      await deleteProfile(id);
    }
  };

  const handleSelect = (id: string) => {
    setActiveProfileId(id);
    onClose();
  };

  return (
    <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.8)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 2000 }}>
      <div style={{ background: "#111111", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "16px", padding: "24px", width: "100%", maxWidth: "400px", color: "#e5e2e1", boxShadow: "0 8px 32px rgba(0,0,0,0.5)", display: "flex", flexDirection: "column", gap: "24px" }}>
        
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h2 style={{ margin: 0, color: "#e9c349", fontFamily: "Manrope, sans-serif" }}>Profiles</h2>
          <button onClick={onClose} style={{ background: "none", border: "none", color: "#a5b8a9", cursor: "pointer" }}><X size={20} /></button>
        </div>

        {isCreating ? (
          <div style={{ display: "flex", flexDirection: "column", gap: "12px", background: "rgba(255,255,255,0.05)", padding: "16px", borderRadius: "12px" }}>
            <h3 style={{ margin: 0, fontSize: "14px", color: "#e9c349" }}>New Profile</h3>
            <input 
              type="text" 
              placeholder="Player Name" 
              value={newName} 
              onChange={(e) => setNewName(e.target.value)} 
              style={{ background: "#1a1a1a", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", padding: "10px", color: "white", outline: "none", fontFamily: "Inter, sans-serif" }} 
              autoFocus
            />
            {errorMsg && <div style={{ color: "#ff6b6b", fontSize: "12px" }}>{errorMsg}</div>}
            <div style={{ display: "flex", gap: "8px", marginTop: "4px" }}>
              <button onClick={() => setIsCreating(false)} style={{ flex: 1, background: "rgba(255,255,255,0.1)", border: "none", borderRadius: "8px", padding: "8px", color: "white", cursor: "pointer" }}>Cancel</button>
              <button onClick={handleCreate} style={{ flex: 1, background: "#e9c349", border: "none", borderRadius: "8px", padding: "8px", color: "#111", fontWeight: "bold", cursor: "pointer" }}>Create</button>
            </div>
          </div>
        ) : (
          <button onClick={() => setIsCreating(true)} style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "8px", background: "rgba(233, 195, 73, 0.1)", border: "1px dashed rgba(233, 195, 73, 0.5)", borderRadius: "12px", padding: "12px", color: "#e9c349", cursor: "pointer", fontFamily: "Inter, sans-serif", fontWeight: 600 }}>
            <Plus size={18} /> Add New Profile
          </button>
        )}

        <div style={{ display: "flex", flexDirection: "column", gap: "8px", maxHeight: "300px", overflowY: "auto" }}>
          {profiles.map(p => (
            <div 
              key={p.id} 
              onClick={() => editProfileId !== p.id && handleSelect(p.id)}
              style={{ 
                display: "flex", alignItems: "center", justifyContent: "space-between", 
                background: p.id === activeProfileId ? "rgba(233, 195, 73, 0.15)" : "rgba(255,255,255,0.05)", 
                border: p.id === activeProfileId ? "1px solid rgba(233, 195, 73, 0.5)" : "1px solid transparent", 
                padding: "12px 16px", borderRadius: "12px", cursor: editProfileId === p.id ? "default" : "pointer",
                transition: "all 0.2s ease"
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "12px", flex: 1 }}>
                <div style={{ width: "32px", height: "32px", borderRadius: "50%", background: "rgba(255,255,255,0.1)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <User size={16} color={p.id === activeProfileId ? "#e9c349" : "#a5b8a9"} />
                </div>
                
                {editProfileId === p.id ? (
                  <div style={{ display: "flex", alignItems: "center", gap: "8px", flex: 1 }}>
                    <input 
                      type="text" 
                      value={editName} 
                      onChange={(e) => setEditName(e.target.value)}
                      onClick={(e) => e.stopPropagation()}
                      style={{ background: "#1a1a1a", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "6px", padding: "6px 8px", color: "white", outline: "none", fontFamily: "Inter, sans-serif", width: "100%", maxWidth: "150px" }} 
                      autoFocus
                    />
                    <button onClick={handleSaveEdit} style={{ background: "#e9c349", border: "none", borderRadius: "4px", padding: "4px 8px", color: "#111", fontWeight: "bold", cursor: "pointer", fontSize: "12px" }}>Save</button>
                    <button onClick={handleCancelEdit} style={{ background: "rgba(255,255,255,0.1)", border: "none", borderRadius: "4px", padding: "4px 8px", color: "white", cursor: "pointer", fontSize: "12px" }}>Cancel</button>
                  </div>
                ) : (
                  <div>
                    <div style={{ fontWeight: 600, color: p.id === activeProfileId ? "#e9c349" : "white" }}>{p.name}</div>
                    {/* Future: show level here, e.g., Level X */}
                    <div style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Last Played: {new Date(p.lastPlayed).toLocaleDateString()}</div>
                  </div>
                )}
              </div>
              
              {editProfileId !== p.id && (
                <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                  <button 
                    onClick={(e) => handleStartEdit(p.id, p.name, e)} 
                    title="Edit Profile"
                    style={{ background: "none", border: "none", color: "rgba(255,255,255,0.3)", cursor: "pointer", padding: "4px" }}
                  >
                    <span style={{ fontSize: "12px", textDecoration: "underline" }}>Edit</span>
                  </button>
                  <button 
                    onClick={(e) => handleDelete(p.id, e)} 
                    title="Delete Profile"
                    style={{ background: "none", border: "none", color: "rgba(255,255,255,0.3)", cursor: "pointer", padding: "4px" }}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
        
      </div>
    </div>
  );
};
