```mermaid
---
title: App Structure
---
flowchart LR
    m[Explore page]
    p[Route preview]
    n[Navigation]
    s[Search page]

    m --Get directions--> p --Start navigation --> n
    m <--Search--> s
    p <--Search--> s
    p -.Exit.-> m
    n -.Exit.-> m