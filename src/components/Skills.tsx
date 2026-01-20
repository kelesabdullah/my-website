"use client";

import { motion } from "framer-motion";
import { Cpu, BadgeCheck, Shield, Cloud, Lock } from "lucide-react";

interface SectionProps {
    progress?: number;
}

const skills = {
    Cloud: ["K8s", "AWS", "GCP", "Azure"],
    Backend: ["Go", "Python", "NestJS", "PostgreSQL"],
    DevOps: ["Terraform", "Ansible", "ArgoCD", "Jenkins"],
    Security: ["OWASP", "Trivy", "SonarQube"],
};

const certs = [
    {
        name: "Certified Kubernetes Administrator",
        code: "CKA",
        issuer: "The Linux Foundation",
        color: "border-blue-500/50 shadow-[0_0_10px_rgba(59,130,246,0.3)]",
        icon: <Cloud className="w-5 h-5 text-blue-400" />
    },
    {
        name: "Azure Administrator Associate",
        code: "AZ-104",
        issuer: "Microsoft",
        color: "border-cyan-500/50 shadow-[0_0_10px_rgba(6,182,212,0.3)]",
        icon: <Lock className="w-5 h-5 text-cyan-400" />
    },
    {
        name: "HCCDA – AI",
        code: "Huawei-AI",
        issuer: "Huawei",
        color: "border-red-500/50 shadow-[0_0_10px_rgba(239,68,68,0.3)]",
        icon: <Cpu className="w-5 h-5 text-red-400" />
    },
    {
        name: "HCCDA – Tech Essentials",
        code: "Huawei-Tech",
        issuer: "Huawei",
        color: "border-red-500/50 shadow-[0_0_10px_rgba(239,68,68,0.3)]",
        icon: <BadgeCheck className="w-5 h-5 text-red-400" />
    },
    {
        name: "HCCDA – Big Data",
        code: "Huawei-BigData",
        issuer: "Huawei",
        color: "border-red-500/50 shadow-[0_0_10px_rgba(239,68,68,0.3)]",
        icon: <BadgeCheck className="w-5 h-5 text-red-400" />
    },
    {
        name: "HCCDA – Cloud Native",
        code: "Huawei-Cloud",
        issuer: "Huawei",
        color: "border-red-500/50 shadow-[0_0_10px_rgba(239,68,68,0.3)]",
        icon: <Cloud className="w-5 h-5 text-red-400" />
    },
    {
        name: "HCCDP – Solution Architectures",
        code: "Huawei-Arch",
        issuer: "Huawei",
        color: "border-red-500/50 shadow-[0_0_10px_rgba(239,68,68,0.3)]",
        icon: <Shield className="w-5 h-5 text-red-400" />
    },
    {
        name: "Fortinet NSE 1",
        code: "NSE-1",
        issuer: "Fortinet",
        color: "border-purple-500/50 shadow-[0_0_10px_rgba(168,85,247,0.3)]",
        icon: <Shield className="w-5 h-5 text-purple-400" />
    },
    {
        name: "Fortinet NSE 2",
        code: "NSE-2",
        issuer: "Fortinet",
        color: "border-purple-500/50 shadow-[0_0_10px_rgba(168,85,247,0.3)]",
        icon: <Shield className="w-5 h-5 text-purple-400" />
    }
];

export default function Skills({ progress = 0 }: SectionProps) {
    return (
        <section className="w-full h-full flex flex-col items-center justify-center p-4 max-w-7xl mx-auto">
            <div className="text-center mb-8 transition-opacity duration-500" style={{ opacity: Math.min(1, progress * 4) }}>
                <h2 className="text-3xl md:text-5xl font-bold font-orbitron text-transparent bg-clip-text bg-gradient-to-r from-secondary to-primary">
                    Tech Arsenal
                </h2>
                <p className="text-sm text-muted-foreground mt-2 uppercase tracking-widest">System Capabilities</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 w-full items-start">
                {/* Skills Column - The Core */}
                <div className="space-y-6">
                    <div className={`flex items-center gap-3 mb-4 transition-all duration-500 ${progress > 0.1 ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-10'}`}>
                        <Cpu className="w-6 h-6 text-primary animate-pulse" />
                        <h3 className="text-2xl font-bold font-orbitron">Core Modules</h3>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {Object.entries(skills).map(([category, items], idx) => {
                            const threshold = 0.15 + (idx * 0.1);
                            const isVisible = progress > threshold;
                            return (
                                <div
                                    key={category}
                                    className={`bg-card/20 border border-white/5 p-5 rounded-xl backdrop-blur-sm transition-all duration-700 transform hover:border-primary/30 ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}
                                >
                                    <h4 className="text-sm font-bold text-secondary mb-3 uppercase tracking-wider">{category}</h4>
                                    <div className="flex flex-wrap gap-2">
                                        {items.map((skill, i) => (
                                            <span key={i} className="px-2 py-1 bg-black/40 rounded text-[11px] font-mono text-gray-300 border border-white/10 hover:border-primary/50 transition-colors cursor-default">
                                                {skill}
                                            </span>
                                        ))}
                                    </div>
                                </div>
                            )
                        })}
                    </div>
                </div>

                {/* Certs Column - The Credentials */}
                <div className="space-y-6">
                    <div className={`flex items-center gap-3 mb-4 transition-all duration-500 delay-200 ${progress > 0.2 ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-10'}`}>
                        <BadgeCheck className="w-6 h-6 text-secondary" />
                        <h3 className="text-2xl font-bold font-orbitron">Clearance Levels</h3>
                    </div>

                    <div className="space-y-3 max-h-[60vh] overflow-y-auto pr-2 no-scrollbar">
                        {certs.map((cert, i) => {
                            const isVisible = progress > (0.3 + i * 0.1);
                            return (
                                <div
                                    key={i}
                                    className={`group relative overflow-hidden bg-card/10 border p-4 rounded-xl flex items-center gap-4 transition-all duration-700 ${cert.color} ${isVisible ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-20'}`}
                                >
                                    {/* Scanning Effect Overlay */}
                                    <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent w-[200%] -translate-x-full group-hover:animate-[shimmer_2s_infinite]" />

                                    <div className="p-3 bg-background/50 rounded-lg border border-white/5">
                                        {cert.icon}
                                    </div>

                                    <div className="flex-1">
                                        <h4 className="text-sm md:text-base font-bold text-foreground font-orbitron">{cert.name}</h4>
                                        <div className="flex items-center gap-2 mt-1">
                                            <span className="text-[10px] font-mono bg-white/5 px-2 py-0.5 rounded text-muted-foreground">{cert.code}</span>
                                            <span className="text-[10px] text-muted-foreground uppercase tracking-wide">{cert.issuer}</span>
                                        </div>
                                    </div>

                                    <div className="hidden md:block">
                                        <span className="text-xs font-mono text-green-400 bg-green-400/10 px-2 py-1 rounded border border-green-400/20">VERIFIED</span>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>
        </section>
    );
}
