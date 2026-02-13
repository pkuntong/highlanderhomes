import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuth } from "@/contexts/AuthContext";
import {
  createExpense,
  createRentPayment,
  listExpenses,
  listProperties,
  listRentPayments,
} from "@/services/dataService";
import { formatCurrency, formatDate, toDateInputValue } from "@/lib/format";

function parseNumber(value) {
  if (value === "" || value === null || value === undefined) return undefined;
  const next = Number(value);
  return Number.isFinite(next) ? next : undefined;
}

function toTimestamp(value) {
  if (!value) return Date.now();
  const timestamp = new Date(`${value}T00:00:00`).getTime();
  return Number.isFinite(timestamp) ? timestamp : Date.now();
}

export default function Finance() {
  const { currentUser } = useAuth();
  const userId = currentUser?._id;
  const queryClient = useQueryClient();
  const [isExpenseOpen, setIsExpenseOpen] = useState(false);
  const [isPaymentOpen, setIsPaymentOpen] = useState(false);

  const [expenseForm, setExpenseForm] = useState({
    propertyId: "",
    title: "",
    amount: "",
    category: "business",
    date: toDateInputValue(Date.now()),
    notes: "",
  });

  const [paymentForm, setPaymentForm] = useState({
    propertyId: "",
    amount: "",
    status: "completed",
    paymentDate: toDateInputValue(Date.now()),
    notes: "",
    paymentMethod: "bank_transfer",
  });

  const propertiesQuery = useQuery({
    queryKey: ["properties", userId],
    queryFn: () => listProperties(userId),
    enabled: Boolean(userId),
  });

  const expensesQuery = useQuery({
    queryKey: ["expenses", userId],
    queryFn: () => listExpenses(userId),
    enabled: Boolean(userId),
  });

  const paymentsQuery = useQuery({
    queryKey: ["rentPayments", userId],
    queryFn: () => listRentPayments(userId),
    enabled: Boolean(userId),
  });

  const createExpenseMutation = useMutation({
    mutationFn: createExpense,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["expenses", userId] });
      setIsExpenseOpen(false);
      setExpenseForm({
        propertyId: "",
        title: "",
        amount: "",
        category: "business",
        date: toDateInputValue(Date.now()),
        notes: "",
      });
    },
  });

  const createPaymentMutation = useMutation({
    mutationFn: createRentPayment,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["rentPayments", userId] });
      setIsPaymentOpen(false);
      setPaymentForm({
        propertyId: "",
        amount: "",
        status: "completed",
        paymentDate: toDateInputValue(Date.now()),
        notes: "",
        paymentMethod: "bank_transfer",
      });
    },
  });

  const propertyMap = useMemo(
    () =>
      Object.fromEntries(
        (propertiesQuery.data || []).map((property) => [
          property._id,
          property.name || `${property.address}, ${property.city}`,
        ])
      ),
    [propertiesQuery.data]
  );

  const totals = useMemo(() => {
    const income = (paymentsQuery.data || [])
      .filter((payment) => payment.status === "completed")
      .reduce((sum, payment) => sum + Number(payment.amount || 0), 0);
    const expenses = (expensesQuery.data || []).reduce(
      (sum, expense) => sum + Number(expense.amount || 0),
      0
    );
    return {
      income,
      expenses,
      net: income - expenses,
    };
  }, [paymentsQuery.data, expensesQuery.data]);

  const transactions = useMemo(() => {
    const expenseRows = (expensesQuery.data || []).map((expense) => ({
      id: `expense-${expense._id}`,
      type: "expense",
      title: expense.title,
      amount: Number(expense.amount || 0),
      date: expense.date,
      propertyId: expense.propertyId,
      status: expense.category,
      notes: expense.notes,
    }));

    const paymentRows = (paymentsQuery.data || []).map((payment) => ({
      id: `payment-${payment._id}`,
      type: "income",
      title: "Rent Payment",
      amount: Number(payment.amount || 0),
      date: payment.paymentDate,
      propertyId: payment.propertyId,
      status: payment.status,
      notes: payment.notes,
    }));

    return [...expenseRows, ...paymentRows].sort((a, b) => b.date - a.date);
  }, [expensesQuery.data, paymentsQuery.data]);

  return (
    <PageLayout
      title="Finance"
      onRefresh={() => {
        expensesQuery.refetch();
        paymentsQuery.refetch();
      }}
      isRefreshing={expensesQuery.isFetching || paymentsQuery.isFetching}
    >
      <div className="space-y-6">
        <section className="grid gap-4 sm:grid-cols-3">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm text-muted-foreground">Total Income</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-semibold text-emerald-600">{formatCurrency(totals.income)}</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm text-muted-foreground">Total Expenses</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-semibold text-rose-600">{formatCurrency(totals.expenses)}</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm text-muted-foreground">Net Cashflow</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-semibold">{formatCurrency(totals.net)}</p>
            </CardContent>
          </Card>
        </section>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-base">Transactions</CardTitle>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => setIsExpenseOpen(true)} className="gap-2">
                <Plus className="h-4 w-4" />
                Add expense
              </Button>
              <Button onClick={() => setIsPaymentOpen(true)} className="gap-2">
                <Plus className="h-4 w-4" />
                Add payment
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {transactions.map((transaction) => (
                <div
                  key={transaction.id}
                  className="flex flex-col gap-2 rounded-md border p-3 md:flex-row md:items-center md:justify-between"
                >
                  <div>
                    <p className="font-medium">{transaction.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {propertyMap[transaction.propertyId] || "Portfolio-level"}
                    </p>
                    <p className="text-xs text-muted-foreground">{formatDate(transaction.date)}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={transaction.type === "income" ? "default" : "secondary"}>
                      {transaction.status}
                    </Badge>
                    <span
                      className={`font-semibold ${
                        transaction.type === "income" ? "text-emerald-600" : "text-rose-600"
                      }`}
                    >
                      {transaction.type === "income" ? "+" : "-"}
                      {formatCurrency(transaction.amount)}
                    </span>
                  </div>
                </div>
              ))}
              {transactions.length === 0 ? (
                <p className="text-center text-sm text-muted-foreground py-8">
                  No transactions yet.
                </p>
              ) : null}
            </div>
          </CardContent>
        </Card>
      </div>

      <Dialog open={isExpenseOpen} onOpenChange={setIsExpenseOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add expense</DialogTitle>
          </DialogHeader>

          <div className="space-y-3">
            <div className="space-y-1">
              <Label>Property</Label>
              <select
                value={expenseForm.propertyId}
                onChange={(event) =>
                  setExpenseForm((prev) => ({ ...prev, propertyId: event.target.value }))
                }
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              >
                <option value="">Portfolio-level</option>
                {(propertiesQuery.data || []).map((property) => (
                  <option key={property._id} value={property._id}>
                    {property.name || property.address}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1">
              <Label>Title</Label>
              <Input
                value={expenseForm.title}
                onChange={(event) =>
                  setExpenseForm((prev) => ({ ...prev, title: event.target.value }))
                }
              />
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <div className="space-y-1">
                <Label>Amount</Label>
                <Input
                  type="number"
                  min="0"
                  value={expenseForm.amount}
                  onChange={(event) =>
                    setExpenseForm((prev) => ({ ...prev, amount: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Category</Label>
                <Input
                  value={expenseForm.category}
                  onChange={(event) =>
                    setExpenseForm((prev) => ({ ...prev, category: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Date</Label>
                <Input
                  type="date"
                  value={expenseForm.date}
                  onChange={(event) =>
                    setExpenseForm((prev) => ({ ...prev, date: event.target.value }))
                  }
                />
              </div>
            </div>
            <div className="space-y-1">
              <Label>Notes</Label>
              <Input
                value={expenseForm.notes}
                onChange={(event) =>
                  setExpenseForm((prev) => ({ ...prev, notes: event.target.value }))
                }
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsExpenseOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={() =>
                createExpenseMutation.mutate({
                  userId,
                  propertyId: expenseForm.propertyId || undefined,
                  title: expenseForm.title.trim(),
                  amount: parseNumber(expenseForm.amount) || 0,
                  category: expenseForm.category.trim() || "business",
                  date: toTimestamp(expenseForm.date),
                  isRecurring: false,
                  notes: expenseForm.notes.trim() || undefined,
                })
              }
              disabled={
                createExpenseMutation.isPending ||
                !expenseForm.title.trim() ||
                !parseNumber(expenseForm.amount)
              }
            >
              {createExpenseMutation.isPending ? "Saving..." : "Save expense"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={isPaymentOpen} onOpenChange={setIsPaymentOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add rent payment</DialogTitle>
          </DialogHeader>

          <div className="space-y-3">
            <div className="space-y-1">
              <Label>Property</Label>
              <select
                value={paymentForm.propertyId}
                onChange={(event) =>
                  setPaymentForm((prev) => ({ ...prev, propertyId: event.target.value }))
                }
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              >
                <option value="">Select property</option>
                {(propertiesQuery.data || []).map((property) => (
                  <option key={property._id} value={property._id}>
                    {property.name || property.address}
                  </option>
                ))}
              </select>
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <div className="space-y-1">
                <Label>Amount</Label>
                <Input
                  type="number"
                  min="0"
                  value={paymentForm.amount}
                  onChange={(event) =>
                    setPaymentForm((prev) => ({ ...prev, amount: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Status</Label>
                <select
                  value={paymentForm.status}
                  onChange={(event) =>
                    setPaymentForm((prev) => ({ ...prev, status: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  <option value="completed">completed</option>
                  <option value="pending">pending</option>
                  <option value="overdue">overdue</option>
                  <option value="cancelled">cancelled</option>
                </select>
              </div>
              <div className="space-y-1">
                <Label>Payment date</Label>
                <Input
                  type="date"
                  value={paymentForm.paymentDate}
                  onChange={(event) =>
                    setPaymentForm((prev) => ({ ...prev, paymentDate: event.target.value }))
                  }
                />
              </div>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Payment method</Label>
                <Input
                  value={paymentForm.paymentMethod}
                  onChange={(event) =>
                    setPaymentForm((prev) => ({ ...prev, paymentMethod: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Notes</Label>
                <Input
                  value={paymentForm.notes}
                  onChange={(event) =>
                    setPaymentForm((prev) => ({ ...prev, notes: event.target.value }))
                  }
                />
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsPaymentOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={() =>
                createPaymentMutation.mutate({
                  userId,
                  propertyId: paymentForm.propertyId,
                  amount: parseNumber(paymentForm.amount) || 0,
                  paymentDate: toTimestamp(paymentForm.paymentDate),
                  status: paymentForm.status,
                  paymentMethod: paymentForm.paymentMethod.trim() || undefined,
                  notes: paymentForm.notes.trim() || undefined,
                })
              }
              disabled={
                createPaymentMutation.isPending ||
                !paymentForm.propertyId ||
                !parseNumber(paymentForm.amount)
              }
            >
              {createPaymentMutation.isPending ? "Saving..." : "Save payment"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </PageLayout>
  );
}
