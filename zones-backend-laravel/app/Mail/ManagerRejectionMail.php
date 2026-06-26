<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ManagerRejectionMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $managerName,
        public string $hallName,
        public string $reason,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'بخصوص طلب انضمام صالتك — Zones',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.manager-rejection',
            with: [
                'managerName' => $this->managerName,
                'hallName' => $this->hallName,
                'reason' => $this->reason,
            ],
            text: 'emails.manager-rejection-text',
        );
    }
}
