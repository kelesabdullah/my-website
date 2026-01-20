"use client";

import { motion } from "framer-motion";
import { Mail, Linkedin, Phone } from "lucide-react";

interface SectionProps {
    progress?: number;
}

export default function Contact({ progress = 0 }: SectionProps) {
    // Simple fade in at the end
    const isVisible = progress > 0.3;

    return (
        <section className="w-full h-full flex flex-col items-center justify-center p-4 max-w-4xl mx-auto">
            <div className={`text-center mb-12 transition-all duration-1000 ${isVisible ? 'opacity-100 scale-100' : 'opacity-0 scale-90'}`}>
                <h2 className="text-3xl md:text-5xl font-bold font-orbitron mb-4">
                    Initialize <span className="text-primary">Handshake</span>
                </h2>
                <p className="text-muted-foreground">Ready to collaborate? Establish a secure connection.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full">
                {[{ icon: <Mail />, label: "Email", href: "mailto:kelesabdullah@protonmail.com" },
                { icon: <Linkedin />, label: "LinkedIn", href: "https://www.linkedin.com/in/kelesabdullah/" },
                { icon: <Phone />, label: "Phone", href: "tel:+905530206401" }].map((contact, idx) => {
                    const delay = isVisible ? 'delay-' + (idx * 200) : '';
                    const show = progress > (0.4 + idx * 0.15);
                    return (
                        <a
                            key={idx}
                            href={contact.href}
                            className={`flex flex-col items-center justify-center p-8 bg-card/30 border backdrop-blur-sm rounded-xl hover:bg-primary/10 transition-all duration-700 transform ${show ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-20'}`}
                        >
                            <div className="mb-4 p-4 rounded-full bg-background/50 text-foreground">{contact.icon}</div>
                            <span className="font-bold">{contact.label}</span>
                        </a>
                    )
                })}
            </div>
        </section>
    );
}
