import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/contexts/AuthContext";
import { listUserProfile, updateUserProfile } from "@/services/dataService";

export default function Profile() {
  const { currentUser, token, updatePassword, refreshSession, logout } = useAuth();
  const userId = currentUser?._id;
  const queryClient = useQueryClient();
  const [profileForm, setProfileForm] = useState({
    name: "",
    email: "",
  });
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const profileQuery = useQuery({
    queryKey: ["userProfile", userId],
    queryFn: () => listUserProfile(userId),
    enabled: Boolean(userId),
  });

  useEffect(() => {
    if (!profileQuery.data) return;
    setProfileForm({
      name: profileQuery.data.name || "",
      email: profileQuery.data.email || "",
    });
  }, [profileQuery.data]);

  const updateMutation = useMutation({
    mutationFn: updateUserProfile,
    onSuccess: async (updated) => {
      await queryClient.invalidateQueries({ queryKey: ["userProfile", userId] });
      refreshSession({
        token,
        user: {
          ...currentUser,
          name: updated.name,
          email: updated.email,
        },
      });
      setMessage("Profile updated.");
      setError("");
    },
    onError: (nextError) => {
      setError(nextError.message);
      setMessage("");
    },
  });

  async function handlePasswordChange(event) {
    event.preventDefault();
    setError("");
    setMessage("");
    try {
      if (passwordForm.newPassword !== passwordForm.confirmPassword) {
        throw new Error("New password and confirmation do not match.");
      }
      await updatePassword({
        email: profileForm.email.trim(),
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
      });
      setPasswordForm({
        currentPassword: "",
        newPassword: "",
        confirmPassword: "",
      });
      setMessage("Password updated.");
    } catch (nextError) {
      setError(nextError.message);
    }
  }

  return (
    <PageLayout title="Profile" onRefresh={() => profileQuery.refetch()} isRefreshing={profileQuery.isFetching}>
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Account</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {profileQuery.isLoading ? <p className="text-sm text-muted-foreground">Loading profile...</p> : null}
            {profileQuery.error ? (
              <p className="text-sm text-red-600">{profileQuery.error.message}</p>
            ) : null}

            <div className="space-y-1">
              <Label>Name</Label>
              <Input
                value={profileForm.name}
                onChange={(event) =>
                  setProfileForm((prev) => ({ ...prev, name: event.target.value }))
                }
              />
            </div>
            <div className="space-y-1">
              <Label>Email</Label>
              <Input
                type="email"
                value={profileForm.email}
                onChange={(event) =>
                  setProfileForm((prev) => ({ ...prev, email: event.target.value }))
                }
              />
            </div>
            <Button
              onClick={() =>
                updateMutation.mutate({
                  userId,
                  name: profileForm.name.trim(),
                  email: profileForm.email.trim(),
                })
              }
              disabled={updateMutation.isPending}
            >
              {updateMutation.isPending ? "Saving..." : "Save profile"}
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Security</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <form onSubmit={handlePasswordChange} className="space-y-3">
              <div className="space-y-1">
                <Label>Current password</Label>
                <Input
                  type="password"
                  value={passwordForm.currentPassword}
                  onChange={(event) =>
                    setPasswordForm((prev) => ({
                      ...prev,
                      currentPassword: event.target.value,
                    }))
                  }
                  required
                />
              </div>
              <div className="space-y-1">
                <Label>New password</Label>
                <Input
                  type="password"
                  value={passwordForm.newPassword}
                  onChange={(event) =>
                    setPasswordForm((prev) => ({
                      ...prev,
                      newPassword: event.target.value,
                    }))
                  }
                  required
                />
              </div>
              <div className="space-y-1">
                <Label>Confirm new password</Label>
                <Input
                  type="password"
                  value={passwordForm.confirmPassword}
                  onChange={(event) =>
                    setPasswordForm((prev) => ({
                      ...prev,
                      confirmPassword: event.target.value,
                    }))
                  }
                  required
                />
              </div>
              <Button type="submit">Change password</Button>
            </form>

            <Button variant="destructive" onClick={logout}>
              Log out
            </Button>

            {message ? <p className="text-sm text-emerald-600">{message}</p> : null}
            {error ? <p className="text-sm text-red-600">{error}</p> : null}
          </CardContent>
        </Card>
      </div>
    </PageLayout>
  );
}
