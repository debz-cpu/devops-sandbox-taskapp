<?php

namespace App\Tests\Entity;

use App\Entity\Task;
use PHPUnit\Framework\TestCase;

class TaskTest extends TestCase
{
    public function testTitleCanBeSetAndRetrieved(): void
    {
        $task = new Task();
        $task->setTitle('Learn CI/CD');

        $this->assertSame('Learn CI/CD', $task->getTitle());
    }

    public function testNewTaskIsNotDoneByDefault(): void
    {
        $task = new Task();
        $task->setIsDone(false);

        $this->assertFalse($task->isDone());
    }
}
