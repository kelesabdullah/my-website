"use client";

import Hero from "@/components/Hero";
import About from "@/components/About";
import Experience from "@/components/Experience";
import Projects from "@/components/Projects";
import Skills from "@/components/Skills";
import Contact from "@/components/Contact";
import { ScrollyContainer } from "@/components/ui/scrolly-container";

export default function Home() {
  return (
    <ScrollyContainer className="font-sans">
      <Hero />
      <About />
      <Experience />
      <Projects />
      <Skills />
      <Contact />
    </ScrollyContainer>
  );
}
