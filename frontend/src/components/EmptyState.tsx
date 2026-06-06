export function EmptyState({ title, action }: { title: string; action?: React.ReactNode }) {
  return (
    <div className="card flex flex-col items-center justify-center gap-3 p-10 text-center">
      <div className="text-5xl">🔬</div>
      <p className="font-bold">{title}</p>
      {action}
    </div>
  );
}
