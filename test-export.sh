#!/bin/bash

# Test script for local export functionality
# Run this to test your setup before pushing to GitHub

set -e

echo "🧪 Testing Org-mode Resume Export System"
echo "========================================"

# Check if required tools are available
echo "📋 Checking dependencies..."

if ! command -v emacs &> /dev/null; then
    echo "❌ Emacs not found. Please install Emacs."
    exit 1
fi
echo "✅ Emacs found"

if ! command -v pdflatex &> /dev/null; then
    echo "❌ pdflatex not found. Please install TeXLive."
    exit 1
fi
echo "✅ pdflatex found"

# Create output directory
mkdir -p test-output
echo "📁 Created test-output directory"

echo ""
echo "📄 Exporting resume..."

# Export resume to PDF
emacs --batch resume.org \
      --eval "(require 'ox-latex)" \
      --eval "(setq org-confirm-babel-evaluate nil)" \
      --eval "(setq org-latex-pdf-process '(\"pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f\" \"pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f\"))" \
      --eval "(org-latex-export-to-pdf)" 2>/dev/null

if [ -f "resume.pdf" ]; then
    mv resume.pdf test-output/ShreyasRagavan-Resume.pdf
    echo "✅ Resume PDF exported successfully"
else
    echo "❌ Resume PDF export failed"
    exit 1
fi

# Export resume to HTML
emacs --batch resume.org \
      --eval "(require 'ox-html)" \
      --eval "(setq org-confirm-babel-evaluate nil)" \
      --eval "(setq org-html-head-include-default-style nil)" \
      --eval "(setq org-html-head \"<style>body{font-family:'Segoe UI',Arial,sans-serif;max-width:800px;margin:0 auto;padding:20px;line-height:1.6;color:#333;}h1{color:#1f4e79;border-bottom:2px solid #1f4e79;text-align:center;}h2{color:#333333;margin-top:1.5em;border-bottom:1px solid #ccc;padding-bottom:5px;}h3{color:#1f4e79;margin-top:1em;}ul{margin-left:20px;}li{margin-bottom:5px;}a{color:#1f4e79;text-decoration:none;}a:hover{text-decoration:underline;}.title{text-align:center;margin-bottom:2em;}.org-ul{list-style-type:disc;}.contact-info{text-align:center;color:#666;margin-bottom:20px;}</style>\")" \
      --eval "(org-html-export-to-html)" 2>/dev/null

if [ -f "resume.html" ]; then
    mv resume.html test-output/ShreyasRagavan-Resume.html
    echo "✅ Resume HTML exported successfully"
else
    echo "❌ Resume HTML export failed"
fi

echo ""
echo "📝 Exporting cover letter..."

# Export cover letter to PDF
emacs --batch cover-letter.org \
      --eval "(require 'ox-latex)" \
      --eval "(setq org-confirm-babel-evaluate nil)" \
      --eval "(setq org-latex-pdf-process '(\"pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f\" \"pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f\"))" \
      --eval "(org-latex-export-to-pdf)" 2>/dev/null

if [ -f "cover-letter.pdf" ]; then
    mv cover-letter.pdf test-output/ShreyasRagavan-CoverLetter.pdf
    echo "✅ Cover letter PDF exported successfully"
else
    echo "❌ Cover letter PDF export failed"
fi

# Export cover letter to HTML
emacs --batch cover-letter.org \
      --eval "(require 'ox-html)" \
      --eval "(setq org-confirm-babel-evaluate nil)" \
      --eval "(setq org-html-head-include-default-style nil)" \
      --eval "(setq org-html-head \"<style>body{font-family:'Segoe UI',Arial,sans-serif;max-width:600px;margin:0 auto;padding:40px;line-height:1.8;color:#333;}h1{color:#1f4e79;text-align:center;margin-bottom:2em;border-bottom:2px solid #1f4e79;}p{margin-bottom:1em;text-align:justify;}a{color:#1f4e79;text-decoration:none;}a:hover{text-decoration:underline;}.contact-info{text-align:center;margin-bottom:2em;color:#666666;}.title{display:none;}</style>\")" \
      --eval "(org-html-export-to-html)" 2>/dev/null

if [ -f "cover-letter.html" ]; then
    mv cover-letter.html test-output/ShreyasRagavan-CoverLetter.html
    echo "✅ Cover letter HTML exported successfully"
else
    echo "❌ Cover letter HTML export failed"
fi

echo ""
echo "🎉 Export test completed!"
echo "📂 Files generated in test-output/:"
ls -la test-output/
echo ""
echo "💡 Tips:"
echo "   - Open the PDF files to verify formatting"
echo "   - Check HTML files in your browser"
echo "   - If exports failed, check for LaTeX errors above"
echo "   - Customize cover letter placeholders in cover-letter.org"