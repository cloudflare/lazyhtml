#ifndef LHTML_TOKENIZER_STATES_H
#define LHTML_TOKENIZER_STATES_H

%%{
    machine html;

    include 'actions.rl';
    include 'parse_errors.rl';
    include '../syntax/index.rl';
}%%

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
%%write data nofinal;
#pragma GCC diagnostic pop

#endif