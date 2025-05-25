<?php

declare(strict_types=1);

use PhpCsFixer\Fixer\Operator\ConcatSpaceFixer;
use Symplify\EasyCodingStandard\Config\ECSConfig;
use Symplify\EasyCodingStandard\ValueObject\Set\SetList;

return ECSConfig::configure()
    ->withPaths([
        __DIR__ . '/src',
        __DIR__ . '/tests'
    ])
    ->withSets([
        SetList::COMMON,
        SetList::PSR_12,
        SetList::CLEAN_CODE,
    ])
    ->withSkip([
        ConcatSpaceFixer::class,
    ]);