"use client";

import { motion } from "framer-motion";
import { Briefcase } from "lucide-react";

interface SectionProps {
    progress?: number;
}

const experienceData = [
    {
        company: "ANKASOFT",
        role: "Software Architect",
        date: "June 2022 - Present",
        desc: "Transformed enterprise systems to Microservices architecture with DDD.",
        tech: ["Kubernetes", "Kafka", "Go"],
    },
    {
        company: "Freelance",
        role: "Developer",
        date: "2022",
        desc: "Developed modular web services using Python & Flask.",
        tech: ["Python", "Flask"],
    },
    {
        company: "TURKCELL",
        role: "Security Intern",
        date: "2021-2022",
        desc: "Security audits for Microservices & Kubernetes.",
        tech: ["Security", "K8s"],
    },
];

export default function Experience({ progress = 0 }: SectionProps) {
    return (
        <section className="w-full h-full flex flex-col items-center justify-center p-4 max-w-5xl mx-auto">
            <div className="text-center mb-8">
                <h2 className="text-3xl md:text-5xl font-bold font-orbitron text-transparent bg-clip-text bg-gradient-to-r from-primary to-secondary">
                    Combat History
                </h2>
                <p className="text-muted-foreground mt-2">
                    Scroll to Load Data... {(progress * 100).toFixed(0)}%
                </p>
            </div>

            <div className="relative border-l-2 border-muted/30 ml-4 md:ml-10 space-y-12 w-full max-w-2xl">
                {experienceData.map((item, idx) => {
                    // Show items sequentially
                    const threshold = 0.1 + (idx * 0.25);
                    const isVisible = progress > threshold;

                    return (
                        <div
                            key={idx}
                            className={`relative pl-8 md:pl-12 transition-all duration-700 ease-out transform ${isVisible ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-10"}`}
                        >
                            {/* Timeline Node */}
                            <div className={`absolute -left-[9px] top-0 w-4 h-4 rounded-full border-2 border-primary transition-colors duration-500 ${isVisible ? "bg-primary shadow-[0_0_10px_rgba(34,211,238,0.5)]" : "bg-background"}`}></div>

                            <div className="bg-card/40 backdrop-blur-sm border border-border p-6 rounded-lg">
                                <h3 className="text-xl font-bold text-foreground">
                                    {item.role} @ {item.company}
                                </h3>
                                <span className="text-sm text-muted-foreground block mb-2">{item.date}</span>
                                <p className="text-sm text-muted-foreground mb-3">{item.desc}</p>
                                <div className="flex gap-2">
                                    {item.tech.map((t, i) => (
                                        <span key={i} className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded border border-primary/20">{t}</span>
                                    ))}
                                </div>
                            </div>
                        </div>
                    );
                })}
            </div>
        </section>
    );
}
