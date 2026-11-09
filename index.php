<?php
declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');

echo "Hello from the MDD PHP stub, served by " . gethostname() . "!\n";
echo "Build: " . (getenv('APP_VERSION') ?: 'dev') . "\n";
