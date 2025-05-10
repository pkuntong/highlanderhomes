import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import * as z from "zod";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { useState, useEffect } from "react";
import { Alert, AlertDescription } from "@/components/ui/alert";

const formSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

export default function Login() {
  const navigate = useNavigate();
  const { login, isAuthenticated, resetPassword } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [resetSent, setResetSent] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [showResetForm, setShowResetForm] = useState(false);
  
  useEffect(() => {
    if (isAuthenticated) {
      navigate("/dashboard");
    }
  }, [isAuthenticated, navigate]);

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "highlanderhomes22@gmail.com",
      password: "",
    },
  });

  async function onSubmit(values) {
    try {
      setError(null);
      setLoading(true);
      const success = await login(values.email, values.password);
      if (success) {
        // Set legacy auth flag in localStorage to support the fallback auth method
        localStorage.setItem("isAuthenticated", "true");
        // Navigate will be handled by the useEffect when isAuthenticated changes
      }
    } catch (err) {
      setError(err.message || "Failed to log in. Please check your credentials.");
    } finally {
      setLoading(false);
    }
  }
  
  const handlePasswordReset = async (e) => {
    e.preventDefault();
    if (!resetEmail) {
      setError("Please enter your email address");
      return;
    }
    
    try {
      setLoading(true);
      setError(null);
      await resetPassword(resetEmail);
      setResetSent(true);
    } catch (err) {
      setError(err.message || "Failed to send password reset email");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-6 p-8 bg-white rounded-lg shadow-lg">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
        </div>
        
        {error && (
          <Alert variant="destructive" className="mb-4">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}
        
        {!showResetForm ? (
          <>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email</FormLabel>
                      <FormControl>
                        <Input placeholder="Enter your email" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Password</FormLabel>
                      <FormControl>
                        <Input type="password" placeholder="Enter your password" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <div className="flex items-center justify-between">
                  <button
                    type="button"
                    onClick={() => setShowResetForm(true)}
                    className="text-sm text-highlander-600 hover:text-highlander-800"
                  >
                    Forgot password?
                  </button>
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Signing in..." : "Sign in"}
                </Button>
              </form>
            </Form>
          </>
        ) : (
          <>
            <div className="space-y-6">
              {resetSent ? (
                <Alert className="bg-green-50 border-green-200">
                  <AlertDescription className="text-green-800">
                    Password reset email sent! Check your inbox.
                  </AlertDescription>
                </Alert>
              ) : (
                <>
                  <h3 className="text-center text-xl font-semibold">Reset Your Password</h3>
                  <p className="text-center text-sm text-gray-600">
                    Enter your email address and we'll send you a link to reset your password.
                  </p>
                  <form onSubmit={handlePasswordReset} className="space-y-4">
                    <div>
                      <label htmlFor="resetEmail" className="block text-sm font-medium text-gray-700">
                        Email address
                      </label>
                      <Input
                        id="resetEmail"
                        type="email"
                        value={resetEmail}
                        onChange={(e) => setResetEmail(e.target.value)}
                        required
                        className="mt-1"
                      />
                    </div>
                    <Button type="submit" className="w-full" disabled={loading}>
                      {loading ? "Sending..." : "Send Reset Link"}
                    </Button>
                  </form>
                </>
              )}
              <div className="text-center">
                <button
                  type="button"
                  onClick={() => {
                    setShowResetForm(false);
                    setResetSent(false);
                    setError(null);
                  }}
                  className="text-sm text-highlander-600 hover:text-highlander-800"
                >
                  Back to login
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
} 