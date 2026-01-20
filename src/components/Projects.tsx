"use client";

import { motion } from "framer-motion";
import { Layers, Server, Cloud } from "lucide-react";

interface SectionProps {
    progress?: number;
}

const projects = [
    {
        title: "Enterprise K8s Platform",
        category: "Cloud Native",
        icon: <Cloud className="w-10 h-10 text-primary" />,
        desc: "RBAC, Logging, Monitoring.",
        tech: ["Kubernetes", "NestJS", "React"],
    },
    {
        title: "Multi-Cloud Automation",
        category: "Infrastructure",
        icon: <Server className="w-10 h-10 text-secondary" />,
        desc: "Unified provisioning for AWS, Azure, GCP.",
        tech: ["Go", ".NET", "Terraform"],
    },
    {
        title: "ANKASOFT Orphia",
        category: "Microservices",
        icon: <Layers className="w-10 h-10 text-purple-400" />,
        desc: "Event-driven platform on GCP.",
        tech: ["Cloud Run", "RabbitMQ", "Pub/Sub"],
    },
];

export default function Projects({ progress = 0 }: SectionProps) {
    return (
        <section className="w-full h-full flex flex-col items-center justify-center p-4 max-w-6xl mx-auto">
            <div className="text-center mb-10 transition-opacity duration-500" style={{ opacity: Math.min(1, progress * 4) }}>
                <h2 className="text-3xl md:text-5xl font-bold font-orbitron mb-2">
                    System <span className="text-secondary">Modules</span>
                </h2>
                <p className="text-muted-foreground">Architected Solutions</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {projects.map((project, idx) => {
                    const threshold = 0.2 + (idx * 0.25);
                    const isVisible = progress > threshold;
                    return (
                        <div
                            key={idx}
                            className={`group relative bg-card/40 border border-border overflow-hidden rounded-xl transition-all duration-700 transform ${isVisible ? 'opacity-100 scale-100 translate-y-0' : 'opacity-0 scale-95 translate-y-20'}`}
                        >
                            <div className="p-6">
                                <div className="mb-4 flex justify-between items-start">
                                    <div className="p-3 bg-secondary/10 rounded-lg">
                                        {project.icon}
                                    </div>
                                </div>
                                <h3 className="text-xl font-bold font-orbitron mb-2">{project.title}</h3>
                                <p className="text-sm text-muted-foreground mb-4">{project.desc}</p>
                                <div className="flex flex-wrap gap-2">
                                    {project.tech.map((t, i) => (
                                        <span key={i} className="px-2 py-1 text-[10px] uppercase font-bold rounded bg-background border border-border text-gray-400">
                                            {t}
                                        </span>
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
