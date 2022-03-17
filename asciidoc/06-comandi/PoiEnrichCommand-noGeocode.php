<?php

namespace App\Command;

use App\Entity\Poi;
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
    const API_KEY = 'la_vostra_chiave_API';
    const TPL_URL = 'http://www.mapquestapi.com/geocoding/v1/reverse?key=%s&location=%f,%f';

    protected static $defaultName = 'poi:enrich';
    private EntityManagerInterface $em;

    public function __construct(EntityManagerInterface $em, string $name = null)
    {
        parent::__construct($name);
        $this->em = $em;
    }

    protected function configure()
    {
        $this
          ->setDescription('Reverse-geocode the POIs missing their address.')
          ->addOption('limit', 'l', InputOption::VALUE_REQUIRED, 'Maximum no. of POIs to enrich')
          ->addOption('info', 'i', InputOption::VALUE_NONE, 'Just print the number of POI to enrich, and exit.')
          ->addOption('stoponerror', 's', InputOption::VALUE_NONE, 'Stop at first error')
          ->addOption('force', 'f', InputOption::VALUE_NONE, 'Actually write data to DB');
    }

    private function mapQuestGeocode(Poi $p)
    {
        $url = sprintf(self::TPL_URL, self::API_KEY, $p->getLat(), $p->getLon());
        $res = curl_init($url);
        curl_setopt($res, CURLOPT_RETURNTRANSFER, true);
        $output = json_decode(curl_exec($res), JSON_OBJECT_AS_ARRAY);
        curl_close($res);

        return $output;
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $limit = $input->getOption('limit');
        $stoponerror = $input->getOption('stoponerror');
        $force = $input->getOption('force');

        if ($input->getOption('info')) {
            $limit = null;
        } else {
            if ($limit <= 0) {
                $io->comment('Automatically limiting the number of records to '.self::DEFAULT_LIMIT);
                $limit = self::DEFAULT_LIMIT;
            }
        }

        $poi = $this->em->getRepository(Poi::class)->findBy(['address' => null], ['updatedAt' => 'ASC'], $limit);

        if ($input->getOption('info')) {
            $io->writeln('Total number of POIs to enrich: <info>'.count($poi).'</info>');

            return Command::SUCCESS;
        }

        // Create progressbar
        $pbar = new ProgressBar($output, count($poi));
        $pbar->start();
        $processed = $errors = 0;

        /** @var Poi $p */
        foreach ($poi as $p) {

            $processed++;

            $output = $this->mapQuestGeocode($p);

//            $io->writeln(print_r($output, true), OutputInterface::VERBOSITY_VERY_VERBOSE);

            if (empty($output['results'][0]['locations'][0])) {
                $pbar->clear();
                $io->writeln('<error>No results</error> for POI #'.$p->getId()." (".$p->getTitle().")");
                $io->writeln(
                  'API returned '.($output ? print_r($output, true) : 'null'),
                  OutputInterface::VERBOSITY_VERBOSE
                );
                if ($stoponerror) {
                    return Command::FAILURE;
                }

                $errors++;
                $pbar->display();
                $pbar->advance();
                continue;
            }

            $pbar->advance();

            /**
             * https://developer.mapquest.com/documentation/geocoding-api/reverse/get/
             */
            if ($force) {
                $result = $output['results'][0]['locations'][0];
                $p
                  ->setAddress($result['street'])
                  ->setCity($result['adminArea5'])
                  ->setCountry($result['adminArea1'])
                  ->setProvince($result['adminArea3'] ?? '-')
                  ->setRegion($result['adminArea3'] ?? '-')
                  ->setZip($result['postalCode']);
                if (!$processed % 50) {
                    $this->em->flush();
                }
            }
        }

        if ($force) {
            $this->em->flush();
        }

        $pbar->finish();
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
