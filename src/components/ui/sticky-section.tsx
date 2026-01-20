"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import { cn } from "@/lib/utils";

interface StickySectionProps {
    children: React.ReactNode;
    className?: string;
    id?: string;
    index: number;
}

export const StickySection = ({ children, className, id, index }: StickySectionProps) => {
    return (
        <div
            id={id}
            className={cn("sticky top-0 h-screen w-full overflow-hidden", className)}
            style={{ zIndex: index }}
        >
            {children}
        </div>
    );
};
