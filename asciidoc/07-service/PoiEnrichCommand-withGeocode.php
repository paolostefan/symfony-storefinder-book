<?php

namespace App\Command;

use App\Entity\Poi;
use App\Service\Geocode;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Helper\ProgressBar;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

class PoiEnrichCommand extends Command
{
    const DEFAULT_LIMIT = 10;
    protected static $defaultName = 'poi:enrich';

    private EntityManagerInterface $em;
    private Geocode $geocode;


    public function __construct(EntityManagerInterface $em, Geocode $geocode, string $name = null)
    {
        parent::__construct($name);
        $this->em = $em;
        $this->geocode = $geocode;
    }

    protected function configure()
    {
        $this
          ->setDescription('Reverse-geocode the POIs missing their address.')
          ->addOption(
            'limit',
            'l',
            InputOption::VALUE_REQUIRED,
            'Maximum no. of POIs to enrich'
          )
          ->addOption(
            'info',
            'i',
            InputOption::VALUE_NONE,
            'Just print the number of POI to enrich, and exit.'
          )
          ->addOption(
            'stoponerror',
            's',
            InputOption::VALUE_NONE,
            'Stop at first error'
          )
          ->addOption(
            'force',
            'f',
            InputOption::VALUE_NONE,
            'Actually write data to DB'
          );
    }


    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $limit = $input->getOption('limit');
        $stopOnError = $input->getOption('stoponerror');
        $force = $input->getOption('force');

        if ($input->getOption('info')) {
            $limit = null;
        } else {
            if ($limit <= 0) {
                $limit = self::DEFAULT_LIMIT;
                $io->comment('Automatically limiting the number of records to '.$limit);
            }
        }

        $poi = $this->em->getRepository(Poi::class)
          ->findBy(['address' => null], ['updatedAt' => 'ASC'], $limit);

        if ($input->getOption('info')) {
            $io->writeln('Total number of POIs to enrich: <info>'.count($poi).'</info>');

            return Command::SUCCESS;
        }

        if(!$poi){
            $io->warning("No Poi to enrich");
            return Command::FAILURE;
        }

        $progressBar = new ProgressBar($output, count($poi));
        $progressBar->start();
        $processed = $errors = 0;

        /** @var Poi $p */
        foreach ($poi as $p) {

            $processed++;

            $output = $this->geocode->callWebservice($p);

            if (empty($output['results'][0]['locations'][0])) {
                $progressBar->clear();
                $io->writeln(
                  '<error>No results</error> for POI #'.
                  $p->getId()." (".$p->getTitle().")"
                );
                $io->writeln(
                  'API returned '.($output ? print_r($output, true) : 'null'),
                  OutputInterface::VERBOSITY_VERBOSE
                );
                if ($stopOnError) {
                    return Command::FAILURE;
                }

                $errors++;
                $progressBar->display();
                $progressBar->advance();
                continue;
            }

            if ($force) {
                $this->geocode->enrich($p);
                if (!$processed % 50) {
                    $this->em->flush();
                }
            }
            $progressBar->advance();
        }

        if ($force) {
            $this->em->flush();
        }

        $progressBar->finish();
        $io->newLine(2);

        if ($force) {
            $io->write("<info>".$processed." POIs</info> processed");
            if ($errors) {
                $io->write(", <error>".$errors." errors</error>");
            }
            $io->newLine();
        } else {
            $io->comment($processed." POIs processed, nothing changed in the DB.");
            $io->note("Use --force to save data to DB.");
        }

        return Command::SUCCESS;
    }
}
