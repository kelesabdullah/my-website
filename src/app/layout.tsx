import type { Metadata } from "next";
import { Inter, Orbitron } from "next/font/google"; // Importing fonts
import "./globals.css";
import { cn } from "@/lib/utils";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const orbitron = Orbitron({ subsets: ["latin"], variable: "--font-orbitron" });

export const metadata: Metadata = {
  title: "Abdullah Keles | Software Architect",
  description: "Senior Software Architect & Cyber-Security Enthusiast. Welcome to my digital realm.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark scroll-smooth">
      <body className={cn(inter.variable, orbitron.variable, "bg-slate-950 font-sans text-slate-100 antialiased selection:bg-cyan-500 selection:text-cyan-950")}>
        <div className="absolute inset-0 bg-[url('/grid.svg')] bg-center [mask-image:linear-gradient(180deg,white,rgba(255,255,255,0))] mix-blend-overlay opacity-20 pointer-events-none fixed z-0"></div>
        <main className="relative z-10 w-full overflow-x-hidden min-h-screen flex flex-col items-center justify-between">
          {children}
        </main>
      </body>
    </html>
  );
}
