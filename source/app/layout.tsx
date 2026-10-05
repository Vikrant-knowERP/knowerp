import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Know Modern ERP Resource Planner",
  description: "Plan resources, project hours and capacity across months.",
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
