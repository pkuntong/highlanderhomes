
import { useState } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { User, Mail, Phone, Lock, LogOut } from "lucide-react";

const Profile = () => {
  const [isEditing, setIsEditing] = useState(false);
  
  // Mock user data
  const [userData, setUserData] = useState({
    name: "John Doe",
    email: "john.doe@highlander.com",
    phone: "(555) 123-4567",
    role: "Property Manager",
    company: "Highlander Homes"
  });

  const handleLogout = () => {
    // In a real app, this would handle logout logic
    console.log("Logging out...");
    // You could add toast notification here
  };

  const handleSaveProfile = () => {
    setIsEditing(false);
    // In a real app, this would save the profile data
    console.log("Saving profile...", userData);
    // You could add toast notification here
  };

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
                      <span>{userData.role}</span>
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

              <Button
                variant="outline"
                className="w-full"
              >
                <Lock className="mr-2 h-4 w-4" />
                Change Password
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </PageLayout>
  );
};

export default Profile;
