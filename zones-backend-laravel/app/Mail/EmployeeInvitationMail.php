<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class EmployeeInvitationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $employeeName,
        public string $roleLabel,
        public string $hallName,
        public string $shiftLabel,
        public string $registrationUrl,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'دعوة للانضمام إلى صالة '.$this->hallName.' — Zones',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.employee-invitation',
            with: [
                'employeeName' => $this->employeeName,
                'roleLabel' => $this->roleLabel,
                'hallName' => $this->hallName,
                'shiftLabel' => $this->shiftLabel,
                'registrationUrl' => $this->registrationUrl,
            ],
            text: 'emails.employee-invitation-text',
        );
    }
}
