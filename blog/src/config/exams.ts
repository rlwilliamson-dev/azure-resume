/**
 * Canonical certification exam structure.
 *
 * This is the single source of truth for domain and objective identifiers. The
 * coverage page renders from it, topic frontmatter is validated against it, and
 * (from phase 3) question banks are too. Nothing else in the codebase should
 * hardcode an objective number.
 *
 * Objective titles are CompTIA's own statements, taken from the released
 * XK0-006 V8 objectives document. The numbers and titles are reproduced because
 * they are how the exam is referenced; the sub-bullet content of that document
 * is copyrighted and is deliberately not reproduced anywhere in this repo.
 *
 * Adding an exam is adding an entry to EXAMS and pointing a track at it in
 * EXAM_FOR_TRACK. No route or component needs to change.
 */

export interface ExamObjective {
  /** Objective number as CompTIA writes it, for example "1.3". */
  id: string;
  /** CompTIA's objective statement. */
  title: string;
}

export interface ExamDomain {
  /** Domain number as CompTIA writes it, for example "1.0". */
  id: string;
  name: string;
  /** Percentage of the exam. Domains in one exam must total 100. */
  weight: number;
  objectives: ExamObjective[];
}

export interface Exam {
  /** Slug used in frontmatter and question banks, for example "xk0-006". */
  id: string;
  name: string;
  /** Vendor's exam code. */
  code: string;
  version: string;
  /** Maximum number of questions on the real exam. */
  questionCount: number;
  /** Length of the real exam in minutes. */
  minutes: number;
  passingScore: number;
  scaleMin: number;
  scaleMax: number;
  domains: ExamDomain[];
}

const xk0006: Exam = {
  id: 'xk0-006',
  name: 'CompTIA Linux+',
  code: 'XK0-006',
  version: 'V8',
  questionCount: 90,
  minutes: 90,
  passingScore: 720,
  scaleMin: 100,
  scaleMax: 900,
  domains: [
    {
      id: '1.0',
      name: 'System Management',
      weight: 23,
      objectives: [
        { id: '1.1', title: 'Explain basic Linux concepts.' },
        { id: '1.2', title: 'Summarize Linux device management concepts and tools.' },
        { id: '1.3', title: 'Given a scenario, manage storage in a Linux system.' },
        {
          id: '1.4',
          title: 'Given a scenario, manage network services and configurations on a Linux server.',
        },
        {
          id: '1.5',
          title: 'Given a scenario, manage a Linux system using common shell operations.',
        },
        {
          id: '1.6',
          title: 'Given a scenario, perform backup and restore operations for a Linux server.',
        },
        { id: '1.7', title: 'Summarize virtualization on Linux systems.' },
      ],
    },
    {
      id: '2.0',
      name: 'Services and User Management',
      weight: 20,
      objectives: [
        { id: '2.1', title: 'Given a scenario, manage files and directories on a Linux system.' },
        {
          id: '2.2',
          title: 'Given a scenario, perform local account management in a Linux environment.',
        },
        {
          id: '2.3',
          title: 'Given a scenario, manage processes and jobs in a Linux environment.',
        },
        {
          id: '2.4',
          title: 'Given a scenario, configure and manage software in a Linux environment.',
        },
        { id: '2.5', title: 'Given a scenario, manage Linux using systemd.' },
        {
          id: '2.6',
          title: 'Given a scenario, manage applications in a container on a Linux server.',
        },
      ],
    },
    {
      id: '3.0',
      name: 'Security',
      weight: 18,
      objectives: [
        { id: '3.1', title: 'Summarize authorization, authentication, and accounting methods.' },
        {
          id: '3.2',
          title: 'Given a scenario, configure and implement firewalls on a Linux system.',
        },
        {
          id: '3.3',
          title:
            'Given a scenario, apply operating system (OS) hardening techniques on a Linux system.',
        },
        { id: '3.4', title: 'Explain account hardening techniques and best practices.' },
        {
          id: '3.5',
          title: 'Explain cryptographic concepts and technologies in a Linux environment.',
        },
        { id: '3.6', title: 'Explain the importance of compliance and audit procedures.' },
      ],
    },
    {
      id: '4.0',
      name: 'Automation, Orchestration, and Scripting',
      weight: 17,
      objectives: [
        {
          id: '4.1',
          title:
            'Summarize the use cases and techniques of automation and orchestration in a Linux environment.',
        },
        { id: '4.2', title: 'Given a scenario, perform automated tasks using shell scripting.' },
        { id: '4.3', title: 'Summarize Python basics used for Linux system administration.' },
        { id: '4.4', title: 'Given a scenario, implement version control using Git.' },
        {
          id: '4.5',
          title: 'Summarize best practices and responsible uses of artificial intelligence (AI).',
        },
      ],
    },
    {
      id: '5.0',
      name: 'Troubleshooting',
      weight: 22,
      objectives: [
        { id: '5.1', title: 'Summarize monitoring concepts and configurations in a Linux system.' },
        {
          id: '5.2',
          title:
            'Given a scenario, analyze and troubleshoot hardware, storage, and Linux OS issues.',
        },
        {
          id: '5.3',
          title: 'Given a scenario, analyze and troubleshoot networking issues on a Linux system.',
        },
        {
          id: '5.4',
          title: 'Given a scenario, analyze and troubleshoot security issues on a Linux system.',
        },
        { id: '5.5', title: 'Given a scenario, analyze and troubleshoot performance issues.' },
      ],
    },
  ],
};

const n10009: Exam = {
  id: 'n10-009',
  name: 'CompTIA Network+',
  code: 'N10-009',
  version: 'V9',
  questionCount: 90,
  minutes: 90,
  passingScore: 720,
  scaleMin: 100,
  scaleMax: 900,
  domains: [
    {
      id: '1.0',
      name: 'Networking Concepts',
      weight: 23,
      objectives: [
        {
          id: '1.1',
          title:
            'Explain concepts related to the Open Systems Interconnection (OSI) reference model.',
        },
        {
          id: '1.2',
          title: 'Compare and contrast networking appliances, applications, and functions.',
        },
        { id: '1.3', title: 'Summarize cloud concepts and connectivity options.' },
        {
          id: '1.4',
          title: 'Explain common networking ports, protocols, services, and traffic types.',
        },
        { id: '1.5', title: 'Compare and contrast transmission media and transceivers.' },
        { id: '1.6', title: 'Compare and contrast network topologies, architectures, and types.' },
        { id: '1.7', title: 'Given a scenario, use appropriate IPv4 network addressing.' },
        { id: '1.8', title: 'Summarize evolving use cases for modern network environments.' },
      ],
    },
    {
      id: '2.0',
      name: 'Network Implementation',
      weight: 20,
      objectives: [
        { id: '2.1', title: 'Explain characteristics of routing technologies.' },
        { id: '2.2', title: 'Given a scenario, configure switching technologies and features.' },
        {
          id: '2.3',
          title: 'Given a scenario, select and configure wireless devices and technologies.',
        },
        { id: '2.4', title: 'Explain important factors of physical installations.' },
      ],
    },
    {
      id: '3.0',
      name: 'Network Operations',
      weight: 19,
      objectives: [
        { id: '3.1', title: 'Explain the purpose of organizational processes and procedures.' },
        { id: '3.2', title: 'Given a scenario, use network monitoring technologies.' },
        { id: '3.3', title: 'Explain disaster recovery (DR) concepts.' },
        { id: '3.4', title: 'Given a scenario, implement IPv4 and IPv6 network services.' },
        { id: '3.5', title: 'Compare and contrast network access and management methods.' },
      ],
    },
    {
      id: '4.0',
      name: 'Network Security',
      weight: 14,
      objectives: [
        { id: '4.1', title: 'Explain the importance of basic network security concepts.' },
        {
          id: '4.2',
          title: 'Summarize various types of attacks and their impact to the network.',
        },
        {
          id: '4.3',
          title:
            'Given a scenario, apply network security features, defense techniques, and solutions.',
        },
      ],
    },
    {
      id: '5.0',
      name: 'Network Troubleshooting',
      weight: 24,
      objectives: [
        { id: '5.1', title: 'Explain the troubleshooting methodology.' },
        {
          id: '5.2',
          title: 'Given a scenario, troubleshoot common cabling and physical interface issues.',
        },
        {
          id: '5.3',
          title: 'Given a scenario, troubleshoot common issues with network services.',
        },
        { id: '5.4', title: 'Given a scenario, troubleshoot common performance issues.' },
        {
          id: '5.5',
          title:
            'Given a scenario, use the appropriate tool or protocol to solve networking issues.',
        },
      ],
    },
  ],
};

export const EXAMS: Record<string, Exam> = {
  [xk0006.id]: xk0006,
  [n10009.id]: n10009,
};

/** Which exam a track's content is written against. Tracks absent here have none. */
export const EXAM_FOR_TRACK: Record<string, string> = {
  'linux-plus': 'xk0-006',
  'network-plus': 'n10-009',
};

/** Exam ids, for the frontmatter and bank schemas to validate against. */
export const EXAM_IDS = Object.keys(EXAMS) as [string, ...string[]];

export function examFor(track: string): Exam | null {
  const id = EXAM_FOR_TRACK[track];
  return id ? (EXAMS[id] ?? null) : null;
}

/** Every objective in an exam, flattened, with its domain attached. */
export function allObjectives(exam: Exam): Array<ExamObjective & { domain: ExamDomain }> {
  return exam.domains.flatMap((domain) => domain.objectives.map((o) => ({ ...o, domain })));
}

/**
 * How many questions each domain contributes to one full weighted exam.
 *
 * Rounding each weight independently does not reliably total the exam length.
 * XK0-006's weights happen to round to exactly 90, which is why three separate
 * call sites got away with `Math.round((weight / 100) * questionCount)` for as
 * long as there was one exam. N10-009's round to 91, so a weighted attempt
 * would have served one question more than the real exam has.
 *
 * Largest remainder fixes it: floor every share, then hand the leftover
 * questions to the domains with the largest fractional parts.
 *
 * Exact ties go to the heavier domain. On N10-009 domains 4.0 and 5.0 both come
 * out at .6, and giving it to 5.0 keeps the largest domain on the exam closest
 * to its published weight, which is the part a candidate would notice. Domain id
 * breaks a tie between equal weights so the split is stable across builds rather
 * than depending on the sort implementation.
 */
export function weightedShares(exam: Exam): Map<string, number> {
  const shares = exam.domains.map((domain) => {
    const exact = (domain.weight / 100) * exam.questionCount;
    const floor = Math.floor(exact);
    return { id: domain.id, weight: domain.weight, count: floor, remainder: exact - floor };
  });

  const shortfall = exam.questionCount - shares.reduce((sum, s) => sum + s.count, 0);
  const byRemainder = [...shares].sort(
    (a, b) => b.remainder - a.remainder || b.weight - a.weight || a.id.localeCompare(b.id)
  );
  for (let i = 0; i < shortfall; i += 1) {
    const target = byRemainder[i % byRemainder.length];
    if (target) target.count += 1;
  }

  return new Map(shares.map((s) => [s.id, s.count]));
}

/** Look up one objective by number, or null. */
export function findObjective(
  exam: Exam,
  objectiveId: string
): (ExamObjective & { domain: ExamDomain }) | null {
  return allObjectives(exam).find((o) => o.id === objectiveId) ?? null;
}

/**
 * Domain weights must total 100, or the weighted practice exam samples the
 * wrong number of questions. Checked at module load so a typo fails the build
 * rather than quietly skewing a score.
 */
for (const exam of Object.values(EXAMS)) {
  const total = exam.domains.reduce((sum, d) => sum + d.weight, 0);
  if (total !== 100) {
    throw new Error(
      `[exams] "${exam.id}" domain weights total ${total}, not 100. Fix the weights in src/config/exams.ts.`
    );
  }
  const ids = allObjectives(exam).map((o) => o.id);
  const duplicate = ids.find((id, i) => ids.indexOf(id) !== i);
  if (duplicate) {
    throw new Error(`[exams] "${exam.id}" lists objective "${duplicate}" more than once.`);
  }
}
