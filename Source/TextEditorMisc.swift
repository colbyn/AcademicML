//
//  TextEditorMisc.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/14/22.
//

import Foundation

let sampleMathText = """
\\macroRules![\\myCmd]{
    [] => {
        Hello World
    }
    [{$0}] => {
        Hello World
    }
    [{$0}{$1}] => {
        Hello World
    }
    [{$0}{$1}{$2}] => {
        Hello World
    }
}

\\myCmd
\\myCmd{}
\\myCmd{1}{2}
\\myCmd{1}{2}{3}
"""

let sampleMathTextComplex = """
\\macroRules![\\math.myCmd]{
    [] => {
        Hello World
    }
    [{$0}] => {
        Hello World
    }
    [{$0}{$1}] => {
        Hello World
    }
    [{$0}{$1}{$2}] => {
        Hello World
    }
}


\\math{
\t\\myCmd
\t\\myCmd{}
\t\\myCmd{1}{2}
\t\\myCmd{1}{2}{3}
}


\\h1{The Quadratic Fromula}
\\math{
    x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}
}

\\h1{Double angle formula for Sine}
\\math{
    \\sin(\\theta + \\phi) = \\sin(\\theta)\\cos(\\phi) + \\sin(\\phi)\\cos(\\theta)
}

\\h1{Divergence Theorem}
\\math{
    \\int_D (\\nabla \\cdot F)\\,\\mathrm{d}V = \\int_{\\partial D} F \\cdot n\\,\\mathrm{d}S
}

\\h1{Standard Deviation}
\\math{
    \\sigma = \\sqrt{ \\frac{1}{N} \\sum_{i=1}^N (x_i - \\mu)^2 }
}

\\h1{Fourier Inverse}
\\math{
    f(x) = \\int_{-\\infty}^{\\infty} \\hat f(\\xi) e^{2\\pi i \\xi x}\\,\\mathrm{d}\\xi
}

\\h1{Cauchy-Schwarz Inequality}
\\math{
    \\left\\vert \\sum_k a_kb_k \\right\\vert \\leq (\\sum_k a_k^2)^{\\frac12}(\\sum_k b_k^2)^{\\frac{1}{2}}
}

\\h1{Exponent}
\\math{
    e = \\lim_{n \\to \\infty}(1 + \\frac{1}{n})^n
}

\\h1{Ramanujan's Identity}
\\math{
    \\frac{1}{\\pi} = \\frac{2\\sqrt{2}}{9801} \\sum_{k=0}^\\infty \\frac{ (4k)! (1103+26390k) }{ (k!)^4 396^{4k} }
}

\\h1{A surprising identity}
\\math{
    \\int_{-\\infty}^{\\infty} \\frac{\\sin(x)}{x}\\,\\mathrm{d}x = \\int_{-\\infty}^{\\infty}\\frac{\\sin^2(x)}{x^2}\\,\\mathrm{d}x
}

\\h1{Another gem from Ramanujan}
\\math{
    \\frac{1}{\\left} = 1 + \\frac{e^{-2\\pi}}{\\right}
}\\where!{
    {\\left} => {
        (\\sqrt{\\phi\\sqrt5} - \\phi) e^{\\frac{2}{5}\\pi}
    }
    {\\right} => {
        1 + \\frac{e^{-4\\pi}}{1 + \\frac{e^{-6\\pi}}{1 + \\frac{e^{-8\\pi}}{1 + \\cdots}}}
    }
}

\\h1{An unneccesary number of scripts}
\\math{
    x^{x^{x^x_x}_{x^x_x}}_{x^{x^x_x}_{x^x_x}}
}

\\h1{Quartic Function}
\\math{
    \\mathop{\\overbrace{c_4x^4 + c_3x^3 + c_2x^2 + c_1x + c_0}}\\limits^{\\gray{\\mathrm{Quartic}}}
}
\\h1{Pythagorean theorem}
\\math{
    \\cos^2{\\theta} + \\sin^2{\\theta} = 1
}
\\note[boxed]{
    \\h3{Symmetric Equation of a Line}
    Given
    \\math{
        t &= \\frac{x - x_1}{x_2-x_1} = \\frac{x - x_1}{\\Delta_x}\\\\
        t &= \\frac{y - y_1}{y_2-y_1} = \\frac{y - y_1}{\\Delta_y}\\\\
        t &= \\frac{z - z_1}{z_2-z_1} = \\frac{z - z_1}{\\Delta_z}
    }
    Therefore
    \\math{
        \\frac{x - x_1}{Delta_x}
            &= \\frac{y - y_1}{\\Delta_y}
            = \\frac{z - z_1}{\\Delta_z}\\\\
                \\frac{x - x_1}{x_2-x_1}
            &= \\frac{y - y_1}{y_2-y_1}
            =  \\frac{z - z_1}{z_2-z_1}
    }
    \\hr
    \\h4{Rationale}
    We rewrite \\{r = r_0 + a = r_0 + t v} in terms of \\{t}.
    That is
    \\math{
        x &= x_1 + t(x_2-x_1) = x_1 + t\\;Delta_x\\\\
        t\\;Delta_x  &= x - x_1 = t(x_2-x_1)\\\\
        t &= \\frac{x - x_1}{x_2-x_1} = \\frac{x - x_1}{Delta_x} \\\\\\\\
        y &= y_1 + t(y_2-y_1) = y_1 + t\\;\\Delta_y\\\\
        t\\;\\Delta_y  &= y - y_1 = t(y_2-y_1)\\\\
        t &= \\frac{y - y_1}{y_2-y_1} = \\frac{y - y_1}{\\Delta_y} \\\\\\\\
        z &= z_1 + t(z_2-z_1) = z_1 + t\\;\\Delta_z\\\\
        t\\;\\Delta_z &= z - z_1 = t(z_2-z_1) \\\\
        t &= \\frac{z - z_1}{z_2-z_1} = \\frac{z - z_1}{\\Delta_z}
    }
}\\where!{
    {\\Delta_x} => {\\colorA{\\Delta_x}}
    {\\Delta_y} => {\\colorA{\\Delta_y}}
    {\\Delta_z} => {\\colorA{\\Delta_z}}
    {x_1} => {\\colorB{x_1}}
    {y_1} => {\\colorB{y_1}}
    {z_1} => {\\colorB{z_1}}
}
"""
