"use client";

import { useRef, useState, useEffect, Children, cloneElement, isValidElement } from "react";
import { motion, useScroll, useMotionValueEvent } from "framer-motion";
import { cn } from "@/lib/utils";

interface ScrollyContainerProps {
    children: React.ReactNode;
    className?: string;
}

export const ScrollyContainer = ({ children, className }: ScrollyContainerProps) => {
    const containerRef = useRef<HTMLDivElement>(null);
    const [activeSection, setActiveSection] = useState(0);
    const [sectionProgress, setSectionProgress] = useState(0);

    const childrenArray = Children.toArray(children);
    const totalSections = childrenArray.length;
    // Reduce height slightly to make scroll faster/more responsive
    const sectionHeight = 100; // 100vh per section
    const totalHeight = totalSections * sectionHeight;

    const { scrollYProgress } = useScroll({
        target: containerRef,
        offset: ["start start", "end end"]
    });

    useMotionValueEvent(scrollYProgress, "change", (latest) => {
        // latest is 0 to 1 over the whole container
        const totalRaw = latest * totalSections;
        const index = Math.min(Math.floor(totalRaw), totalSections - 1);
        const progress = totalRaw - index; // 0 to 1 representing the % of CURRENT section

        if (index !== activeSection) {
            setActiveSection(index);
        }
        setSectionProgress(progress);
    });

    return (
        <div
            ref={containerRef}
            style={{ height: `${totalHeight}vh` }}
            className={cn("w-full bg-background relative", className)}
        >
            <div className="fixed top-0 left-0 h-screen w-full overflow-hidden">
                {/* Progress Bar */}
                <div className="absolute top-0 left-0 w-full h-1 bg-muted/20 z-50">
                    <motion.div
                        className="h-full bg-primary"
                        style={{ width: `${(activeSection + sectionProgress) / totalSections * 100}%` }}
                    />
                </div>

                {childrenArray.map((child, index) => {
                    const isActive = index === activeSection;

                    // We keep all sections rendered but control visibility.
                    // This prevents mounting/unmounting flicker/blankness.
                    return (
                        <div
                            key={index}
                            className={cn(
                                "absolute inset-0 w-full h-full transition-opacity duration-500 flex items-center justify-center p-4",
                                isActive ? "opacity-100 z-10 pointer-events-auto" : "opacity-0 z-0 pointer-events-none"
                            )}
                        >
                            {isValidElement(child)
                                /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
                                ? cloneElement(child as React.ReactElement, { progress: isActive ? sectionProgress : 0 } as any)
                                : child
                            }
                        </div>
                    );
                })}

                {/* Navigation Dots */}
                <div className="absolute right-4 top-1/2 -translate-y-1/2 flex flex-col gap-2 z-50">
                    {childrenArray.map((_, idx) => (
                        <button
                            key={idx}
                            onClick={() => {
                                window.scrollTo({ top: window.innerHeight * idx, behavior: 'smooth' });
                            }}
                            className={cn(
                                "w-2 h-2 rounded-full transition-all duration-300",
                                idx === activeSection ? "bg-primary h-6" : "bg-muted-foreground/30 hover:bg-primary/50"
                            )}
                        />
                    ))}
                </div>
            </div>
        </div>
    );
};
