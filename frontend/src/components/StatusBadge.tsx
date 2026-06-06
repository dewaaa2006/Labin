const tones: Record<string, string> = {
  PENDING: 'bg-amber-100 text-amber-700',
  APPROVED: 'bg-emerald-100 text-emerald-700',
  TAKEN: 'bg-cyan-100 text-cyan-700',
  RETURNED: 'bg-emerald-100 text-emerald-700',
  REJECTED: 'bg-red-100 text-red-700',
  CANCELLED: 'bg-slate-100 text-slate-700',
  RECEIVED: 'bg-cyan-100 text-cyan-700',
  IN_PROGRESS: 'bg-amber-100 text-amber-700',
  RESOLVED: 'bg-emerald-100 text-emerald-700',
};

export function StatusBadge({ value }: { value: string }) {
  return <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${tones[value] ?? 'bg-slate-100 text-slate-700'}`}>{value}</span>;
}
