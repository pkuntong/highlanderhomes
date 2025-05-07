import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { User, Mail, Phone, Lock, LogOut } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useNavigate } from "react-router-dom";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { db } from "@/firebase";
import { doc, getDoc, setDoc } from "firebase/firestore";

const defaultUserData = {
  name: "John Doe",
  email: "john.doe@highlander.com",
  phone: "(555) 123-4567",
  role: "Property Manager",
  company: "Highlander Homes"
};

const PROFILE_DOC_ID = "main"; // You can use a static doc id for single-user or use auth uid for multi-user

const Profile = () => {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [isEditing, setIsEditing] = useState(false);
  const [userData, setUserData] = useState(defaultUserData);
  const [loading, setLoading] = useState(true);
  const [isChangePasswordOpen, setIsChangePasswordOpen] = useState(false);
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [passwordError, setPasswordError] = useState("");

  // Load from Firestore on mount
  useEffect(() => {
    async function fetchProfile() {
      setLoading(true);
      const docRef = doc(db, "profile", PROFILE_DOC_ID);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        setUserData(docSnap.data());
      }
      setLoading(false);
    }
    fetchProfile();
  }, []);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const handleSaveProfile = async () => {
    setIsEditing(false);
    const docRef = doc(db, "profile", PROFILE_DOC_ID);
    await setDoc(docRef, userData);
  };

  const handlePasswordChange = (e) => {
    const { name, value } = e.target;
    setPasswordForm(prev => ({ ...prev, [name]: value }));
  };

  const handlePasswordSubmit = (e) => {
    e.preventDefault();
    setPasswordError("");
    const storedPassword = localStorage.getItem("highlanderhomes_password") || "highlander2025";
    if (passwordForm.currentPassword !== storedPassword) {
      setPasswordError("Current password is incorrect.");
      return;
    }
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      setPasswordError("New password and confirmation do not match.");
      return;
    }
    // Save new password to localStorage
    localStorage.setItem("highlanderhomes_password", passwordForm.newPassword);
    setIsChangePasswordOpen(false);
    setPasswordForm({
      currentPassword: "",
      newPassword: "",
      confirmPassword: "",
    });
  };

  if (loading) return <div>Loading profile...</div>;

  return (
    <PageLayout title="Profile">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Account Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="name">Full Name</Label>
                    <div className="flex items-center mt-1">
                      <User className="h-4 w-4 text-gray-500 mr-2" />
                      {isEditing ? (
                        <Input
                          id="name"
                          value={userData.name}
                          onChange={(e) => 
                            setUserData({ ...userData, name: e.target.value })
                          }
                        />
                      ) : (
                        <span>{userData.name}</span>
                      )}
                    </div>
                  </div>

                  <div>
                    <Label htmlFor="role">Role</Label>
                    <div className="flex items-center mt-1">
                      <Lock className="h-4 w-4 text-gray-500 mr-2" />
                      {isEditing ? (
                        <select
                          id="role"
                          className="border rounded px-2 py-1 text-sm"
                          value={userData.role}
                          onChange={(e) =>
                            setUserData({ ...userData, role: e.target.value })
                          }
                        >
                          <option value="Property Manager">Property Manager</option>
                          <option value="Landlord">Landlord</option>
                        </select>
                      ) : (
                        <span>{userData.role}</span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="email">Email Address</Label>
                    <div className="flex items-center mt-1">
                      <Mail className="h-4 w-4 text-gray-500 mr-2" />
                      {isEditing ? (
                        <Input
                          id="email"
                          type="email"
                          value={userData.email}
                          onChange={(e) =>
                            setUserData({ ...userData, email: e.target.value })
                          }
                        />
                      ) : (
                        <span>{userData.email}</span>
                      )}
                    </div>
                  </div>

                  <div>
                    <Label htmlFor="phone">Phone Number</Label>
                    <div className="flex items-center mt-1">
                      <Phone className="h-4 w-4 text-gray-500 mr-2" />
                      {isEditing ? (
                        <Input
                          id="phone"
                          value={userData.phone}
                          onChange={(e) =>
                            setUserData({ ...userData, phone: e.target.value })
                          }
                        />
                      ) : (
                        <span>{userData.phone}</span>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="pt-4 flex justify-end space-x-2">
                  {isEditing ? (
                    <>
                      <Button variant="outline" onClick={() => setIsEditing(false)}>
                        Cancel
                      </Button>
                      <Button onClick={handleSaveProfile}>Save Changes</Button>
                    </>
                  ) : (
                    <Button onClick={() => setIsEditing(true)}>Edit Profile</Button>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="lg:col-span-1">
          <Card>
            <CardHeader>
              <CardTitle>Account Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button 
                variant="destructive" 
                className="w-full" 
                onClick={handleLogout}
              >
                <LogOut className="mr-2 h-4 w-4" />
                Logout
              </Button>

              <Dialog open={isChangePasswordOpen} onOpenChange={setIsChangePasswordOpen}>
                <DialogTrigger asChild>
                  <Button
                    variant="outline"
                    className="w-full"
                  >
                    <Lock className="mr-2 h-4 w-4" />
                    Change Password
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Change Password</DialogTitle>
                  </DialogHeader>
                  <form onSubmit={handlePasswordSubmit} className="space-y-4">
                    {passwordError && (
                      <div className="text-red-600 text-sm font-medium">{passwordError}</div>
                    )}
                    <div>
                      <Label htmlFor="currentPassword">Current Password</Label>
                      <Input
                        id="currentPassword"
                        name="currentPassword"
                        type="password"
                        value={passwordForm.currentPassword}
                        onChange={handlePasswordChange}
                        required
                      />
                    </div>
                    <div>
                      <Label htmlFor="newPassword">New Password</Label>
                      <Input
                        id="newPassword"
                        name="newPassword"
                        type="password"
                        value={passwordForm.newPassword}
                        onChange={handlePasswordChange}
                        required
                      />
                    </div>
                    <div>
                      <Label htmlFor="confirmPassword">Confirm New Password</Label>
                      <Input
                        id="confirmPassword"
                        name="confirmPassword"
                        type="password"
                        value={passwordForm.confirmPassword}
                        onChange={handlePasswordChange}
                        required
                      />
                    </div>
                    <div className="flex justify-end space-x-2">
                      <Button
                        variant="outline"
                        type="button"
                        onClick={() => setIsChangePasswordOpen(false)}
                      >
                        Cancel
                      </Button>
                      <Button type="submit">Change Password</Button>
                    </div>
                  </form>
                </DialogContent>
              </Dialog>
            </CardContent>
          </Card>
        </div>
      </div>
    </PageLayout>
  );
};

export default Profile;
