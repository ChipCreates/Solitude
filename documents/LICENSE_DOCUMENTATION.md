# Solitude - License Documentation

Complete licensing information for Solitude and its dependencies.

## Table of Contents

1. [Project License](#project-license)
2. [GPL-3.0 Explained](#gpl-30-explained)
3. [Your Rights as a User](#your-rights-as-a-user)
4. [Your Obligations as a Developer](#your-obligations-as-a-developer)
5. [Third-Party Licenses](#third-party-licenses)
6. [License Compatibility](#license-compatibility)
7. [FAQ](#faq)
8. [Full License Text](#full-license-text)

---

## Project License

**Solitude** is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

**What this means:**
- The software is **free and open source**
- You can use it for any purpose (personal, educational, commercial)
- You can modify and distribute it
- If you distribute modified versions, you must also release them under GPL-3.0
- You must make the source code available

**License File:** See [LICENSE](../LICENSE) in the project root.

**Copyright:** © 2024 Solitude Contributors

---

## GPL-3.0 Explained

The GNU General Public License version 3.0 is a **copyleft** license that ensures software freedom.

### Core Principles

#### 1. Freedom to Use
You can use Solitude for any purpose:
- Personal entertainment
- Educational projects
- Commercial products (with conditions)
- Research and development
- Derivative works

**No restrictions on use cases.**

#### 2. Freedom to Study
You can examine how Solitude works:
- Full source code is available
- No obfuscation or hidden functionality
- Complete documentation provided
- Ability to learn from the implementation

**Transparency is guaranteed.**

#### 3. Freedom to Modify
You can change Solitude to suit your needs:
- Fix bugs
- Add features
- Customize appearance
- Optimize performance
- Remove unwanted functionality

**Complete modification rights.**

#### 4. Freedom to Share
You can distribute Solitude:
- Original version
- Modified versions
- As part of a larger project (with conditions)

**But: Modified versions must also be GPL-3.0.**

### Copyleft Requirement

**Key concept:** If you distribute Solitude (modified or unmodified), you must:

1. **Provide source code** to recipients
2. **Use GPL-3.0 license** for your modifications
3. **Include license and copyright notices**
4. **Document your changes**

**Example scenario:**
```
You modify Solitude to add Spider Solitaire
→ You distribute your version on a website
→ You must provide the full source code
→ Your version must be GPL-3.0 licensed
→ Users receive the same freedoms you had
```

This prevents "taking" open source software private.

---

## Your Rights as a User

### What You Can Do

#### Use Freely
- Install and run Solitude on any device
- Play as much as you want
- Use for personal or professional purposes
- No registration, activation, or fees required

#### Examine the Code
- Read the entire source code
- Understand how features work
- Learn programming techniques
- Audit for security or privacy concerns

#### Share with Others
- Give copies to friends, family, colleagues
- Post download links
- Include in software collections
- Recommend to others

**No limitations on personal use and sharing.**

### What You DON'T Need to Do

As a user (not distributor), you are **NOT required to**:
- Share your settings or saved games
- Contribute back to the project
- Report bugs (though appreciated!)
- Register or identify yourself
- Pay any fees

**Using GPL software carries no obligations unless you distribute it.**

---

## Your Obligations as a Developer

### When Obligations Apply

GPL-3.0 obligations activate when you **distribute** Solitude:

**Distribution includes:**
- Publishing modified versions online
- Selling apps based on Solitude
- Including in software bundles
- Providing to users/customers
- Deploying as a web service (see AGPL note)

**Distribution does NOT include:**
- Using internally in your company
- Modifying for personal use only
- Running on your own server for yourself

### Your Obligations When Distributing

#### 1. Provide Source Code

You must make the complete source code available:

**Options:**
- Include source code with the distribution
- Provide a download link (valid for 3+ years)
- Written offer to provide source (physical media)

**What to include:**
- All source files needed to build the software
- Build scripts and compilation instructions
- Documentation and configuration files
- Installation instructions

**Example:**
```
If you publish a Solitude APK on Google Play:
→ You must provide a link to the source code
→ The source must include all your modifications
→ Build instructions must be included
→ The link must remain valid for 3+ years
```

#### 2. Use GPL-3.0 License

Your distributed version must be GPL-3.0:

**Requirements:**
- Include the full GPL-3.0 license text
- Do NOT add additional restrictions
- Do NOT remove or change copyright notices
- Apply GPL-3.0 to your modifications

**You cannot:**
- Relicense under MIT, Apache, or proprietary licenses
- Add "no commercial use" restrictions
- Require registration or fees for the source code
- Use different licenses for different parts (unless separately licensed)

#### 3. Preserve Notices

You must keep all existing notices:

**Include:**
- Copyright statements
- License headers in source files
- Attribution to original authors
- Notices about warranty disclaimer

**Add:**
- Your own copyright for your changes
- Notices describing your modifications
- Date of changes

**Example header:**
```dart
// Copyright (C) 2024 Solitude Contributors
// Copyright (C) 2025 Your Name (modifications)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// See LICENSE file for full license text.
```

#### 4. Document Changes

Clearly indicate what you've changed:

**Good practices:**
- Maintain a CHANGELOG.md file
- Use git commit messages
- Add comments in modified code
- Create a MODIFICATIONS.md document

**Example:**
```markdown
# Modifications from Original Solitude

- Added Spider Solitaire game mode (2025-01-15)
- Changed default theme to Ocean Teal (2025-01-20)
- Fixed audio bug on Android 14 (2025-01-22)
```

#### 5. No Additional Restrictions

You cannot add restrictions beyond GPL-3.0:

**Prohibited:**
- "Only for non-commercial use"
- "Cannot be used by competitors"
- "Must pay for commercial use"
- "Requires registration"
- DRM or technical protection measures

**Allowed:**
- Offering commercial support contracts
- Selling physical media (must include source)
- Dual licensing YOUR original code (not Solitude code)

---

## Third-Party Licenses

Solitude incorporates components with different licenses. All are compatible with GPL-3.0.

### 1. SVG Playing Cards

**Project:** htdebeer/SVG-cards
**Author:** David Bellot (original), Huub de Beer (maintainer)
**License:** GNU Lesser General Public License 2.1+ (LGPL-2.1+)
**Source:** https://github.com/htdebeer/SVG-cards
**Files:** `assets/cards/svg-cards.svg`

**LGPL-2.1+ Summary:**
- More permissive than GPL-3.0
- Allows use in GPL-3.0 projects (compatible)
- Modifications to the SVG file itself should be LGPL
- Using the SVG as a resource (not modifying it) has no restrictions

**Attribution Required:**
```
SVG Playing Cards by David Bellot
Maintained by Huub de Beer
Licensed under LGPL 2.1 or later
https://github.com/htdebeer/SVG-cards
```

**Obligations:**
- Include attribution in your app (About screen, credits)
- If you modify the SVG file, release modifications under LGPL-2.1+
- Provide a copy of LGPL-2.1 license text

### 2. Inter Font Family

**Project:** Inter typeface
**Author:** Rasmus Andersson
**License:** SIL Open Font License 1.1 (OFL-1.1)
**Source:** https://rsms.me/inter/
**Files:** `assets/fonts/*.ttf`

**OFL-1.1 Summary:**
- Font can be used freely in any project
- Can be bundled with software (even commercial)
- Font name "Inter" is reserved (don't rename modified versions to "Inter")
- Very permissive, GPL-compatible

**Attribution Required:**
```
Inter font family by Rasmus Andersson
Licensed under SIL Open Font License 1.1
https://rsms.me/inter/
```

**Obligations:**
- Include attribution in your app
- Don't rename modified fonts to "Inter"
- Provide OFL-1.1 license text if distributing font separately

### 3. Flutter Framework

**Project:** Flutter
**Author:** Google LLC
**License:** BSD 3-Clause License
**Source:** https://github.com/flutter/flutter

**BSD-3-Clause Summary:**
- Very permissive license
- Allows use in any project (including GPL-3.0)
- No copyleft requirements
- Only requires attribution

**Attribution Required:**
```
Flutter Framework
Copyright (c) Google LLC
Licensed under BSD 3-Clause License
```

**Obligations:**
- Include attribution (automatically in Flutter apps)
- Include BSD-3-Clause license text
- No source code disclosure requirements

### 4. Dart Packages

All dependencies use permissive licenses compatible with GPL-3.0:

| Package | License | Attribution |
|---------|---------|-------------|
| flutter_svg | MIT | Copyright flutter_svg authors |
| xml | MIT | Copyright xml package authors |
| shared_preferences | BSD-3-Clause | Copyright Google LLC |
| provider | MIT | Copyright Remi Rousselet |
| collection | BSD-3-Clause | Copyright Google LLC |
| audioplayers | MIT | Copyright audioplayers authors |

**MIT License Summary:**
- Very permissive
- Allows any use
- Requires attribution
- GPL-compatible

**Obligations for all packages:**
- Include attribution in app credits
- Provide license text (usually in LICENSES file)

---

## License Compatibility

### Understanding Compatibility

**GPL-3.0 is compatible with:**
- LGPL-2.1, LGPL-3.0 (can incorporate LGPL code)
- MIT, BSD, Apache-2.0 (can incorporate permissive code)
- Other GPL-3.0 code (obviously)

**GPL-3.0 is NOT compatible with:**
- GPL-2.0-only (must be "GPL-2.0 or later")
- Proprietary licenses (closed source)
- Some copyleft licenses (e.g., EPL, MPL without secondary licensing)

### Incorporating Other Code

**Can you add code from other projects?**

| Other License | Can Incorporate? | Notes |
|---------------|------------------|-------|
| GPL-3.0 | Yes | Same license |
| GPL-2.0+ | Yes | "or later" allows GPL-3.0 |
| GPL-2.0-only | No | Incompatible with GPL-3.0 |
| LGPL-2.1+, LGPL-3.0 | Yes | Compatible |
| MIT, BSD, Apache-2.0 | Yes | Can be combined with GPL |
| Proprietary | No | Incompatible |
| Public Domain | Yes | No restrictions |

**Best practice:** Always check licenses before incorporating code.

### Dual Licensing

**Can you dual-license Solitude?**

**No**, because:
- You don't own all the code (third-party components)
- SVG cards are LGPL (not yours to relicense)
- Contributors hold copyright on their contributions

**Can you dual-license YOUR additions?**

**Yes**, you can license your original code under multiple licenses:
- Your new game mode could be MIT + GPL-3.0
- But when combined with Solitude, the result is GPL-3.0
- Allows others to use your code separately under MIT

---

## FAQ

### General Questions

**Q: Can I use Solitude commercially?**
A: Yes. You can use it for commercial purposes, but if you distribute a modified version, you must provide source code under GPL-3.0.

**Q: Can I sell Solitude or modified versions?**
A: Yes, you can charge for distribution (physical media, app store fees, etc.), but you must provide the source code to recipients and they have the right to redistribute for free.

**Q: Do I need to open-source my game if I use Solitude's code?**
A: Only if you distribute it. If it's for personal use, no. If you distribute it, yes.

**Q: Can I remove the GPL license and use a different one?**
A: No. The code is GPL-3.0, and you must keep it GPL-3.0. You cannot relicense others' code.

### Distribution Questions

**Q: I modified Solitude for my company's internal use. Do I need to share the code?**
A: No. Internal use within a company is not "distribution" and triggers no GPL obligations.

**Q: I'm hosting a web version of Solitude. Is that distribution?**
A: Under GPL-3.0, network use alone is not distribution. However, consider using AGPL-3.0 if you want to require source sharing for network services.

**Q: I built an app with Solitude and published it on the app store. What do I do?**
A: You must provide the full source code (including your modifications) to users, typically via a link in the app's description or About screen.

**Q: Can I provide just the modified files instead of the whole source?**
A: No. You must provide the complete corresponding source code, including all files needed to build the software.

### Modification Questions

**Q: I want to add a feature but don't want to release it. What can I do?**
A: As long as you don't distribute your modified version, you can keep it private. Personal use has no sharing requirement.

**Q: Can I contribute my feature back to Solitude?**
A: Yes! Contributions are welcome. By contributing, you agree to license your contribution under GPL-3.0.

**Q: What if I want to use a different license for my contribution?**
A: You can offer your contribution under dual licenses (e.g., MIT + GPL-3.0), but it will be incorporated under GPL-3.0 in Solitude.

### Technical Questions

**Q: Do I need to include the GPL license text in every source file?**
A: Best practice is to include a short header in each file and provide the full license text in a LICENSE file.

**Q: How do I comply with GPL-3.0 when distributing a compiled app?**
A: Include a prominent notice about GPL-3.0, provide a link to the source code, and ensure the link remains valid for at least 3 years.

**Q: Can I use Solitude's code as a reference without copying it?**
A: If you don't copy any code, GPL-3.0 doesn't apply. Learning from GPL code and implementing similar ideas independently is allowed.

### Third-Party Questions

**Q: The SVG cards are LGPL, not GPL. Can I use them separately?**
A: Yes. The LGPL is more permissive. You can use the SVG cards in non-GPL projects if you comply with LGPL-2.1+.

**Q: Can I replace the SVG cards with my own graphics?**
A: Yes. If you replace LGPL components with your own, only the GPL-3.0 applies (for the Solitude code).

**Q: What about the fonts? Can I use them in non-GPL projects?**
A: Yes. The Inter fonts are OFL-1.1, which allows use in any project.

---

## Full License Text

The complete GNU General Public License v3.0 text is available in the [LICENSE](../LICENSE) file in the project root.

**Key sections:**

### Preamble
Explains the philosophy and purpose of the GPL.

### Terms and Conditions

**Section 0: Definitions**
Defines terms like "modify", "convey", "source code", etc.

**Section 1: Source Code**
Defines what constitutes "corresponding source code".

**Section 2: Basic Permissions**
Grants rights to run, modify, and propagate the software.

**Section 4: Conveying Verbatim Copies**
Rules for distributing unmodified copies.

**Section 5: Conveying Modified Versions**
Rules for distributing modified versions.

**Section 6: Conveying Non-Source Forms**
Rules for distributing compiled binaries.

**Section 7: Additional Terms**
Allowed additional permissions.

**Section 10-17: Miscellaneous**
Patent grants, warranty disclaimers, liability limitations.

### How to Apply GPL-3.0 to Your Modifications

```
Copyright (C) <year> <your name>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```

---

## Additional Resources

### Official GPL Resources

- **GPL-3.0 Full Text:** https://www.gnu.org/licenses/gpl-3.0.html
- **GPL FAQ:** https://www.gnu.org/licenses/gpl-faq.html
- **Quick Guide:** https://www.gnu.org/licenses/quick-guide-gplv3.html
- **GPL Compliance Guide:** https://www.gnu.org/licenses/gpl-howto.html

### Understanding Copyleft

- **What is Copyleft?** https://www.gnu.org/licenses/copyleft.html
- **Why GPL?** https://www.gnu.org/philosophy/why-copyleft.html

### License Compatibility

- **GPL Compatibility:** https://www.gnu.org/licenses/license-compatibility.html
- **License List:** https://www.gnu.org/licenses/license-list.html

### Legal Advice

**Disclaimer:** This documentation provides general information about GPL-3.0 and is not legal advice. For specific legal questions, consult a qualified attorney specializing in intellectual property and open source licensing.

---

## Credits and Attribution

### Required Attributions

When distributing Solitude or derivative works, include these attributions:

```
SOLITUDE - Solitaire Card Game
Copyright (C) 2024 Solitude Contributors
Licensed under GNU General Public License v3.0

THIRD-PARTY COMPONENTS:

SVG Playing Cards
Copyright (C) David Bellot
Maintained by Huub de Beer
Licensed under LGPL 2.1 or later
https://github.com/htdebeer/SVG-cards

Inter Font Family
Copyright (C) Rasmus Andersson
Licensed under SIL Open Font License 1.1
https://rsms.me/inter/

Flutter Framework
Copyright (C) Google LLC
Licensed under BSD 3-Clause License
https://flutter.dev

Dart Packages:
- flutter_svg (MIT)
- xml (MIT)
- shared_preferences (BSD-3-Clause)
- provider (MIT)
- collection (BSD-3-Clause)
- audioplayers (MIT)

See CREDITS.md for complete attribution details.
```

---

## Version History

**License Documentation Version 1.0**
Created: 2024
Updated: 2025-01-15

For updates to this documentation, see the git history:
```bash
git log -- documents/LICENSE_DOCUMENTATION.md
```

---

## Contact

For licensing questions or concerns:

- **GitHub Issues:** https://github.com/plotworx/solitude/issues
- **Email:** See project repository for contact information

For legal matters, consult a qualified attorney.

---

**Thank you for respecting free software licenses!**

By honoring the GPL-3.0 license, you help ensure that Solitude and its derivatives remain free and open for everyone.
