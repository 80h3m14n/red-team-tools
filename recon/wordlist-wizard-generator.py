import itertools
import argparse
from datetime import datetime
import shlex
import sys
import os
import json
import csv
import pyperclip  # pip install pyperclip

# --- Banner ---
BANNER = r"""
   
  
██     ██  ██████  ██████  ██████  ██      ██ ███████ ████████     ██     ██ ██ ███████  █████  ██████  ██████  
██     ██ ██    ██ ██   ██ ██   ██ ██      ██ ██         ██        ██     ██ ██    ███  ██   ██ ██   ██ ██   ██ 
██  █  ██ ██    ██ ██████  ██   ██ ██      ██ ███████    ██        ██  █  ██ ██   ███   ███████ ██████  ██   ██ 
██ ███ ██ ██    ██ ██   ██ ██   ██ ██      ██      ██    ██        ██ ███ ██ ██  ███    ██   ██ ██   ██ ██   ██ 
 ███ ███   ██████  ██   ██ ██████  ███████ ██ ███████    ██         ███ ███  ██ ███████ ██   ██ ██   ██ ██████  
                                                                                                                                                                       

                                                    
        Custom Wordlist Generator (CUPP++ Clone)
"""

# --- Maps and Constants ---
LEET_MAP = {
    'a': ['a', '@', '4'],
    'e': ['e', '3'],
    'i': ['i', '1', '!'],
    'o': ['o', '0'],
    's': ['s', '$', '5'],
    't': ['t', '7'],
    'l': ['l', '1']
}

SPECIAL_CHARS = ['!', '@', '#', '$', '%', '&', '*']
COMMON_SUFFIXES = ['123', '1234', '12345', '!', str(datetime.now().year)]

# --- Helper: Load base words from file ---


def load_words_from_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f if line.strip()]
    except Exception as e:
        print(f"[!] Error loading file: {e}")
        return []

# --- Helper: Load base words from clipboard ---


def load_words_from_clipboard():
    try:
        text = pyperclip.paste()
        return [line.strip() for line in text.splitlines() if line.strip()]
    except Exception as e:
        print(f"[!] Error reading clipboard: {e}")
        return []

# --- Helper: Blacklist filter ---


def filter_blacklist(wordlist, blacklist):
    return [w for w in wordlist if all(b not in w for b in blacklist)]

# --- Helper: Common password filter ---


def filter_common_passwords(wordlist, common_file='common_passwords.txt'):
    if not os.path.exists(common_file):
        return wordlist
    with open(common_file, 'r', encoding='utf-8') as f:
        common = set(line.strip() for line in f)
    return [w for w in wordlist if w not in common]

# --- Helper: Password strength checker (very basic) ---


def password_strength(word):
    score = 0
    if any(c.islower() for c in word):
        score += 1
    if any(c.isupper() for c in word):
        score += 1
    if any(c.isdigit() for c in word):
        score += 1
    if any(c in SPECIAL_CHARS for c in word):
        score += 1
    if len(word) >= 8:
        score += 1
    return score

# --- Leetspeak Gen ---


def leetspeak(word):
    def helper(w, i):
        if i == len(w):
            return ['']
        rest = helper(w, i + 1)
        char = w[i].lower()
        replacements = LEET_MAP.get(char, [char])
        return [r + s for r in replacements for s in rest]
    return list(set(helper(word, 0)))

# --- Wordlist Generator ---


def generate_wordlist(
    data, max_len=3, min_len=1, use_leet=True, use_special=True, use_suffix=True,
    separators=None, case_variations=False, reverse_words=False, pattern=None
):
    base_words = [data['name'], data['nickname'],
                  data['partner'], data['pet'], data['birthyear']]
    base_words += data.get('extra_words', [])
    base_words = list(filter(None, base_words))

    leet_words = [w for word in base_words for w in leetspeak(
        word)] if use_leet else []
    all_words = base_words + leet_words

    combos = set()
    sep_list = separators if separators else ['']
    for i in range(1, len(all_words) + 1):
        for combo in itertools.permutations(all_words, i):
            for sep in sep_list:
                word = sep.join(combo)
                if reverse_words:
                    combos.add(word[::-1])
                combos.add(word)

    # Pattern-based generation
    if pattern:
        pattern_words = set()
        for combo in combos:
            pat = pattern.replace('{word}', combo)
            pattern_words.add(pat)
        combos = pattern_words

    # Case variations
    if case_variations:
        case_words = set()
        for w in combos:
            case_words.add(w.lower())
            case_words.add(w.upper())
            case_words.add(w.capitalize())
        combos |= case_words

    # Suffixes and specials
    wordlist = set()
    for word in combos:
        if not (min_len <= len(word) <= max_len):
            continue
        wordlist.add(word)
        if use_suffix:
            for suffix in COMMON_SUFFIXES:
                sw = word + suffix
                if min_len <= len(sw) <= max_len:
                    wordlist.add(sw)
        if use_special:
            for char in SPECIAL_CHARS:
                sw = word + char
                if min_len <= len(sw) <= max_len:
                    wordlist.add(sw)

    return sorted(wordlist)

# --- Interactive Classic Mode ---


def interactive_shell():
    print("\n[Interactive Mode] Enter target details (leave blank to skip):")
    data = {
        'name': input("Name: ").strip(),
        'nickname': input("Nickname: ").strip(),
        'partner': input("Partner name: ").strip(),
        'pet': input("Pet name: ").strip(),
        'birthyear': input("Birth year: ").strip()
    }
    # Extra words from file/clipboard
    extra = []
    if input("Load extra words from file? (y/N): ").strip().lower() == 'y':
        path = input("File path: ").strip()
        extra += load_words_from_file(path)
    if input("Load extra words from clipboard? (y/N): ").strip().lower() == 'y':
        extra += load_words_from_clipboard()
    data['extra_words'] = extra

    try:
        minlen = int(input("Min combo length (default 1): ").strip() or "1")
    except ValueError:
        minlen = 1
    try:
        maxlen = int(input("Max combo length (default 12): ").strip() or "12")
    except ValueError:
        maxlen = 12
    use_leet = input("Enable leetspeak combos? (y/N): ").strip().lower() == 'y'
    use_special = input(
        "Enable special characters? (Y/n): ").strip().lower() != 'n'
    use_suffix = input(
        "Enable common suffixes? (Y/n): ").strip().lower() != 'n'
    case_variations = input(
        "Enable case variations? (y/N): ").strip().lower() == 'y'
    reverse_words = input(
        "Include reversed words? (y/N): ").strip().lower() == 'y'
    sep = input("Word separators (comma separated, blank for none): ").strip()
    separators = [s for s in sep.split(',') if s] if sep else ['']
    pattern = input(
        "Pattern (use {word} as placeholder, blank for none): ").strip() or None
    blacklist = input(
        "Blacklist words/patterns (comma separated, blank for none): ").strip().split(',')
    blacklist = [b.strip() for b in blacklist if b.strip()]
    limit = input("Limit number of passwords (blank for no limit): ").strip()
    limit = int(limit) if limit.isdigit() else None
    output_format = input(
        "Output format (txt/csv/json, default txt): ").strip().lower() or "txt"
    default_output = f"{data['name'] or 'custom_wordlist'}.{output_format}"
    output = input(f"Output file name (default: {default_output}): ").strip() or default_output

    if os.path.exists(output):
        print(f"[!] Warning: {output} already exists and will be overwritten.")

    print("[*] Generating...")
    words = generate_wordlist(
        data,
        min_len=minlen,
        max_len=maxlen,
        use_leet=use_leet,
        use_special=use_special,
        use_suffix=use_suffix,
        separators=separators,
        case_variations=case_variations,
        reverse_words=reverse_words,
        pattern=pattern
    )
    if blacklist:
        words = filter_blacklist(words, blacklist)
    if input("Filter out common passwords? (y/N): ").strip().lower() == 'y':
        words = filter_common_passwords(words)
    if limit:
        words = words[:limit]

    # Output
    if output_format == "csv":
        with open(output, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            for word in words:
                writer.writerow([word])
    elif output_format == "json":
        with open(output, 'w', encoding='utf-8') as f:
            json.dump(words, f, indent=2)
    else:
        with open(output, 'w', encoding='utf-8') as f:
            for word in words:
                f.write(f"{word}\n")

    print(f"[+] Done! Generated {len(words)} passwords → {output}")
    print("[*] Sample passwords:")
    for w in words[:10]:
        print("  ", w)
    print("[*] Password strength (first 10):")
    for w in words[:10]:
        print(f"  {w}: {password_strength(w)}/5")

# --- Interactive CLI Flag Shell ---


def interactive_flag_shell(parser):
    print("\n[Interactive CLI Mode] Enter flags as you would on the command line (e.g., --name John --leet --maxlen 2)")
    print("Press Enter with no input to exit.")
    while True:
        user_input = input("\nFlags: ").strip()
        if not user_input:
            print("Exiting interactive shell.")
            sys.exit(0)
        try:
            args = parser.parse_args(shlex.split(user_input))
            run_with_args(args)
            break
        except SystemExit:
            print("\n[!] Invalid flags or arguments. Please try again.\n")
            parser.print_help()


def run_with_args(args):
    if not getattr(args, 'quiet', False):
        print(BANNER)

    data = {
        'name': args.name or '',
        'nickname': args.nickname or '',
        'partner': args.partner or '',
        'pet': args.pet or '',
        'birthyear': args.birthyear or '',
        'extra_words': []
    }
    if args.extra_file:
        data['extra_words'] += load_words_from_file(args.extra_file)
    if args.extra_clipboard:
        data['extra_words'] += load_words_from_clipboard()

    # Set output file name based on --name and format if output is default
    output_file = args.output
    if output_file == 'custom_wordlist.txt':
        base = data['name'] if data['name'] else 'custom_wordlist'
        ext = args.format
        output_file = f"{base}.{ext}"

    if os.path.exists(output_file):
        print(
            f"[!] Warning: {output_file} already exists and will be overwritten.")

    if not getattr(args, 'quiet', False):
        print("[*] Generating...")

    words = generate_wordlist(
        data,
        min_len=args.minlen,
        max_len=args.maxlen,
        use_leet=args.leet,
        use_special=not args.no_special,
        use_suffix=not args.no_suffix,
        separators=args.separators,
        case_variations=args.case_variations,
        reverse_words=args.reverse_words,
        pattern=args.pattern
    )
    if args.blacklist:
        words = filter_blacklist(words, args.blacklist)
    if args.filter_common:
        words = filter_common_passwords(words, args.common_file)
    if args.limit:
        words = words[:args.limit]

    # Output
    if args.format == "csv":
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            for word in words:
                writer.writerow([word])
    elif args.format == "json":
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(words, f, indent=2)
    else:
        with open(output_file, 'w', encoding='utf-8') as f:
            for word in words:
                f.write(f"{word}\n")

    if not getattr(args, 'quiet', False):
        print(f"[+] Done! Generated {len(words)} passwords → {output_file}")
        print("[*] Sample passwords:")
        for w in words[:10]:
            print("  ", w)
        print("[*] Password strength (first 10):")
        for w in words[:10]:
            print(f"  {w}: {password_strength(w)}/5")

# --- Main CLI ---


def main():
    parser = argparse.ArgumentParser(
        description="🎯 Wordlist Generator\n\nRun without arguments for interactive CLI mode.\nUse --I for manual prompt mode.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('--name', help='Target name')
    parser.add_argument('--nickname', help='Nickname')
    parser.add_argument('--partner', help='Partner name')
    parser.add_argument('--pet', help='Pet name')
    parser.add_argument('--birthyear', help='Birth year')
    parser.add_argument('--extra-file', help='File with extra words')
    parser.add_argument('--extra-clipboard', action='store_true',
                        help='Load extra words from clipboard')

    parser.add_argument('--minlen', type=int, default=1,
                        help='Min combo length (default: 1)')
    parser.add_argument('--maxlen', type=int, default=12,
                        help='Max combo length (default: 12)')
    parser.add_argument(
        '--output', default='custom_wordlist.txt', help='Output file name')
    parser.add_argument(
        '--format', choices=['txt', 'csv', 'json'], default='txt', help='Output format')

    parser.add_argument('--leet', action='store_true',
                        help='Enable leetspeak combos')
    parser.add_argument('--no-special', action='store_true',
                        help='Disable special characters')
    parser.add_argument('--no-suffix', action='store_true',
                        help='Disable common suffixes')
    parser.add_argument('--case-variations',
                        action='store_true', help='Enable case variations')
    parser.add_argument('--reverse-words', action='store_true',
                        help='Include reversed words')
    parser.add_argument('--separators', nargs='*',
                        default=[''], help='Word separators (space separated, e.g. _ - .)')
    parser.add_argument(
        '--pattern', help='Pattern (use {word} as placeholder)')
    parser.add_argument('--blacklist', nargs='*', default=[],
                        help='Blacklist words/patterns')
    parser.add_argument('--limit', type=int, help='Limit number of passwords')
    parser.add_argument('--filter-common', action='store_true',
                        help='Filter out common passwords')
    parser.add_argument(
        '--common-file', default='common_passwords.txt', help='File with common passwords')
    parser.add_argument('--quiet', action='store_true',
                        help='Suppress banner and logs')
    parser.add_argument('--I', action='store_true',
                        help='Launch classic interactive input mode')

    if len(sys.argv) == 1:
        print(BANNER)
        parser.print_help()
        print("\n[?] To enter interactive mode, type: I")
        print("[?] Or enter CLI flags as you would on the command line (e.g., --name John --leet --maxlen 2)")
        while True:
            user_input = input("\nInput: ").strip()
            if user_input.lower() == "I":
                interactive_shell()
                return
            elif not user_input:
                print("Exiting.")
                sys.exit(0)
            else:
                try:
                    args = parser.parse_args(shlex.split(user_input))
                    run_with_args(args)
                    break
                except SystemExit:
                    print("\n[!] Invalid flags or arguments. Please try again.\n")
                    parser.print_help()
                    print("\n[?] To enter interactive mode, type: I")
        return

    args = parser.parse_args()

    if args.I:
        interactive_shell()
        return

    run_with_args(args)


if __name__ == '__main__':
    main()
