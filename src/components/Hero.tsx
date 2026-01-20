"use client";

import { motion } from "framer-motion";
import { GlitchText } from "./ui/glitch-text";
import { ArrowDown } from "lucide-react";

interface SectionProps {
    progress?: number;
}

export default function Hero({ progress }: SectionProps) {
    // Use progress to animate if needed, e.g. opacity fading out near end
    const opacity = progress ? Math.max(0, 1 - progress * 1.5) : 1;

    return (
        <section className="relative w-full h-screen flex flex-col items-center justify-center overflow-hidden">
            <div className="z-10 text-center px-4">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                >
                    <span className="text-secondary tracking-[0.2em] text-sm md:text-base font-medium uppercase mb-4 block">
                        Welcome to the Network
                    </span>
                </motion.div>

                <motion.h1
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.8, delay: 0.2 }}
                    className="text-5xl md:text-8xl font-bold mb-2 tracking-tighter"
                >
                    <GlitchText text="ABDULLAH KELES" className="text-foreground" />
                </motion.h1>

                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ duration: 1, delay: 0.5 }}
                    className="relative inline-block"
                >
                    <div className="absolute inset-0 bg-primary blur-[40px] opacity-20 h-full w-full rounded-full"></div>
                    <h2 className="relative text-2xl md:text-4xl text-primary font-orbitron font-medium mt-2">
                        SOFTWARE ARCHITECT
                    </h2>
                </motion.div>

                <motion.p
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ duration: 1, delay: 0.8 }}
                    className="mt-6 text-muted-foreground max-w-lg mx-auto text-sm md:text-base leading-relaxed"
                >
                    Architecting scalable microservices by day. <br />
                    Chasing EDM beats by night.
                </motion.p>

                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 1, delay: 1.2 }}
                    className="mt-12 flex gap-4 justify-center"
                >
                    <button
                        onClick={() => window.scrollTo({ top: window.innerHeight * 3, behavior: 'smooth' })} // Projects is index 3
                        className="px-8 py-3 bg-primary/10 border border-primary text-primary hover:bg-primary hover:text-primary-foreground transition-all duration-300 font-orbitron text-sm tracking-wider uppercase backdrop-blur-sm cursor-pointer"
                    >
                        View Projects
                    </button>
                    <button
                        onClick={() => window.scrollTo({ top: window.innerHeight * 5, behavior: 'smooth' })} // Contact is index 5
                        className="px-8 py-3 bg-secondary/10 border border-secondary text-secondary hover:bg-secondary hover:text-secondary-foreground transition-all duration-300 font-orbitron text-sm tracking-wider uppercase backdrop-blur-sm cursor-pointer"
                    >
                        Contact Me
                    </button>
                </motion.div>
            </div>

            <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 2, duration: 1 }}
                className="absolute bottom-10 left-1/2 -translate-x-1/2"
            >
                <ArrowDown className="w-6 h-6 text-muted-foreground animate-bounce" />
            </motion.div>
        </section>
    );
}
