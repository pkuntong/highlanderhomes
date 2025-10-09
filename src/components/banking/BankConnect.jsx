import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Building2, CheckCircle, AlertCircle, Loader2 } from "lucide-react";

export default function BankConnect({ onConnect }) {
  const [connecting, setConnecting] = useState(false);
  const [connectedBanks, setConnectedBanks] = useState([]);

  const handleConnectBank = async () => {
    setConnecting(true);

    // Simulate Plaid Link integration
    setTimeout(() => {
      const newBank = {
        id: Date.now(),
        name: "Chase Bank",
        accountType: "Checking",
        last4: "1234",
        status: "connected"
      };

      setConnectedBanks([...connectedBanks, newBank]);
      setConnecting(false);

      if (onConnect) {
        onConnect(newBank);
      }
    }, 2000);
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-5 w-5" />
            Bank Connections
          </CardTitle>
          <CardDescription>
            Connect your bank account to enable automated rent collection
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {connectedBanks.length > 0 && (
              <div className="space-y-3">
                {connectedBanks.map((bank) => (
                  <div
                    key={bank.id}
                    className="flex items-center justify-between p-4 border rounded-lg"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-10 w-10 bg-blue-100 rounded-full flex items-center justify-center">
                        <Building2 className="h-5 w-5 text-blue-600" />
                      </div>
                      <div>
                        <p className="font-medium">{bank.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {bank.accountType} """" {bank.last4}
                        </p>
                      </div>
                    </div>
                    <Badge className="bg-green-100 text-green-700">
                      <CheckCircle className="h-3 w-3 mr-1" />
                      Connected
                    </Badge>
                  </div>
                ))}
              </div>
            )}

            {connectedBanks.length === 0 && (
              <div className="text-center py-8 border-2 border-dashed rounded-lg">
                <Building2 className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <p className="text-sm text-muted-foreground mb-4">
                  No bank accounts connected yet
                </p>
              </div>
            )}

            <Button
              onClick={handleConnectBank}
              disabled={connecting}
              className="w-full"
            >
              {connecting ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Connecting...
                </>
              ) : (
                <>
                  <Building2 className="h-4 w-4 mr-2" />
                  Connect Bank Account
                </>
              )}
            </Button>

            <div className="flex items-start gap-2 p-3 bg-blue-50 rounded-lg">
              <AlertCircle className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-blue-900">
                Bank connections are secured with bank-level encryption.
                We never store your banking credentials.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
