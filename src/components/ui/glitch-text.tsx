"use client";

import { motion } from "framer-motion";

interface GlitchTextProps {
    text: string;
    className?: string;
}

export const GlitchText = ({ text, className = "" }: GlitchTextProps) => {
    return (
        <div className={`relative inline-block group ${className}`}>
            <span className="relative z-10">{text}</span>
            <motion.span
                className="absolute inset-0 text-primary opacity-0 group-hover:opacity-100 select-none"
                initial={{ x: 0 }}
                animate={{ x: [-2, 2, -2] }}
                transition={{ repeat: Infinity, duration: 0.2 }}
            >
                {text}
            </motion.span>
            <motion.span
                className="absolute inset-0 text-secondary opacity-0 group-hover:opacity-100 select-none"
                initial={{ x: 0 }}
                animate={{ x: [2, -2, 2] }}
                transition={{ repeat: Infinity, duration: 0.2, delay: 0.1 }}
            >
                {text}
            </motion.span>
        </div>
    );
};
