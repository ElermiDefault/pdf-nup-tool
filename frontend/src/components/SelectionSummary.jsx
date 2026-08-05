const LAYOUT_OPTIONS = [2, 3, 4, 5, 8];

function buildContinuousRanges(numbers) {
  const sortedNumbers = [...numbers].sort((a, b) => a - b);
  const ranges = [];

  for (const number of sortedNumbers) {
    const previous = ranges[ranges.length - 1];
    if (previous && number === previous.end + 1) {
      previous.end = number;
    } else {
      ranges.push({ start: number, end: number });
    }
  }

  return ranges;
}

function SelectionSummary({
  activeTaskId,
  exportRules,
  onActivateTask,
  onClear,
  onCreateTask,
  onDeleteTask,
  onLayoutChange,
  pageItems,
  tasks,
}) {
  return (
    <section className="selection-panel">
      <div className="selection-header">
        <div>
          <h2>Merge tasks</h2>
          <p>
            {tasks.length === 0
              ? 'Create a task, then click pages to assign them.'
              : `${tasks.length} task${tasks.length > 1 ? 's' : ''}`}
          </p>
        </div>

        <div className="task-create-group" aria-label="Create merge task">
          {LAYOUT_OPTIONS.map((layout) => (
            <button
              className="secondary-button"
              key={layout}
              type="button"
              onClick={() => onCreateTask(layout)}
            >
              New {layout} in 1
            </button>
          ))}
        </div>
      </div>

      {tasks.length === 0 ? (
        <div className="empty-inline">No merge tasks yet. Export still works for combining and reordering pages.</div>
      ) : (
        <>
          <div className="task-list">
            {tasks.map((task, index) => (
              <MergeTask
                isActive={task.id === activeTaskId}
                key={task.id}
                onActivateTask={onActivateTask}
                onDeleteTask={onDeleteTask}
                onLayoutChange={onLayoutChange}
                pageItems={pageItems}
                task={task}
                taskNumber={index + 1}
              />
            ))}
          </div>

          <div className="rules-preview">
            <div className="rules-preview-title">Generated ordered rules</div>
            <pre>{JSON.stringify(exportRules, null, 2)}</pre>
          </div>

          <button type="button" className="secondary-button clear-button" onClick={onClear}>
            Clear all tasks
          </button>
        </>
      )}
    </section>
  );
}

function MergeTask({
  isActive,
  onActivateTask,
  onDeleteTask,
  onLayoutChange,
  pageItems,
  task,
  taskNumber,
}) {
  const pageById = new Map(pageItems.map((page, index) => [page.id, { ...page, position: index + 1 }]));
  const selectedPages = task.pageIds.map((pageId) => pageById.get(pageId)).filter(Boolean);
  const ranges = buildContinuousRanges(selectedPages.map((page) => page.position));
  const pageText =
    ranges.length === 0
      ? 'No pages assigned'
      : ranges
          .map((range) =>
            range.start === range.end
              ? `Position ${range.start}`
              : `Positions ${range.start}-${range.end}`,
          )
          .join(', ');
  const sourceText =
    selectedPages.length === 0
      ? ''
      : selectedPages
          .slice(0, 3)
          .map((page) => `${page.filename} p.${page.pageNumber}`)
          .join(', ');
  const overflowText = selectedPages.length > 3 ? ` +${selectedPages.length - 3} more` : '';

  return (
    <article
      className={`merge-task${isActive ? ' is-active' : ''}`}
      style={{ '--range-color': task.color }}
    >
      <div className="task-main">
        <button
          type="button"
          className="task-activate"
          aria-pressed={isActive}
          onClick={() => onActivateTask(task.id)}
        >
          <span className="task-color" />
          <span className="task-label">
            <strong>Task {taskNumber}</strong>
            <span>{pageText}</span>
            {sourceText ? <span>{sourceText}{overflowText}</span> : null}
            {selectedPages.length > 1 ? <em>Grouped move</em> : null}
          </span>
        </button>
      </div>

      <div className="layout-control" role="group" aria-label={`Layout for task ${taskNumber}`}>
        {LAYOUT_OPTIONS.map((option) => (
          <button
            className={`layout-option${task.layout === option ? ' is-active' : ''}`}
            key={option}
            type="button"
            onClick={() => onLayoutChange(task.id, option)}
          >
            {option} in 1
          </button>
        ))}
      </div>

      <button type="button" className="task-delete" onClick={() => onDeleteTask(task.id)}>
        Delete
      </button>
    </article>
  );
}

export default SelectionSummary;
