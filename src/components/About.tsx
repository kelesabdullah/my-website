"use client";

import { motion } from "framer-motion";
import { Music, Code, Database, Globe } from "lucide-react";

interface SectionProps {
    progress?: number;
}

export default function About({ progress = 0 }: SectionProps) {
    // Reveal cards based on progress
    // 0-0.2: Intro Text
    // 0.2-1.0: Cards one by one

    const cards = [
        {
            icon: <Code className="w-8 h-8 text-primary" />,
            title: "Tech Stack",
            desc: "Architecting robust systems with Go, Python, and Next.js.",
            color: "border-primary/20",
        },
        {
            icon: <Database className="w-8 h-8 text-secondary" />,
            title: "Data & Cloud",
            desc: "Kubernetes, AWS, and GCP expert. Scaling is my game.",
            color: "border-secondary/20",
        },
        {
            icon: <Music className="w-8 h-8 text-pink-500" />,
            title: "The Beat",
            desc: "Fueled by EDM. Armin van Buuren & Tiesto are my productivity hacks.",
            color: "border-pink-500/20",
        },
        {
            icon: <Globe className="w-8 h-8 text-cyan-400" />,
            title: "Global Mindset",
            desc: "Based in Turkey, building world-class software solutions.",
            color: "border-cyan-400/20",
        },
    ];

    return (
        <section id="about" className="w-full h-full flex flex-col items-center justify-center p-4">
            <div className="max-w-7xl mx-auto w-full grid grid-cols-1 md:grid-cols-2 gap-10 items-center">
                {/* Text Content - Always visible initially, maybe fade out? */}
                <div className="opacity-100 transition-opacity duration-500">
                    <div className="flex items-center gap-2 mb-4">
                        <span className="h-[1px] w-12 bg-secondary"></span>
                        <span className="text-secondary font-orbitron tracking-widest text-sm uppercase">About Me</span>
                    </div>
                    <h2 className="text-3xl md:text-5xl font-bold mb-6">
                        Connecting <span className="text-primary">Systems</span> & <span className="text-secondary">Beats</span>
                    </h2>
                    <p className="text-muted-foreground leading-relaxed mb-6">
                        I'm a Software Architect mixing high-availablity systems with high-energy beats.
                    </p>
                </div>

                {/* Cards Grid - Reveal based on progress */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {cards.map((card, idx) => {
                        // Calculate if this card should be shown
                        // idx 0 shows at > 0.2
                        // idx 1 shows at > 0.4
                        // idx 2 shows at > 0.6
                        // idx 3 shows at > 0.8
                        const threshold = 0.2 + (idx * 0.2);
                        const isVisible = progress > threshold;

                        return (
                            <div
                                key={idx}
                                className={`p-6 bg-card/30 backdrop-blur-md border ${card.color} rounded-lg transition-all duration-700 transform ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-20'}`}
                            >
                                <div className="mb-4 p-3 bg-background/50 rounded-full w-fit">
                                    {card.icon}
                                </div>
                                <h3 className="text-xl font-bold mb-2 font-orbitron">{card.title}</h3>
                                <p className="text-sm text-muted-foreground">{card.desc}</p>
                            </div>
                        );
                    })}
                </div>
            </div>
        </section>
    );
}
